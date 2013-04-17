#
# This file is part of meego-test-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# Authors: Sami Hangaslammi <sami.hangaslammi@leonidasoy.fi>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# version 2.1 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA
#

require 'testreport'
require 'csv'
require 'trimmer'
require 'report_parser'
require 'validation/date_time_validator'
require 'file_storage'

require 'graph'
require 'nft'
require 'array_nested_hashing'

#noinspection Rails3Deprecated
class MeegoTestSession < ActiveRecord::Base
  include Trimmer
  include Graph
  include MeasurementUtils
  include CacheHelper

  belongs_to :author, :class_name => "User"
  belongs_to :editor, :class_name => "User"
  belongs_to :release
  belongs_to :profile

  has_many :features,         :dependent => :destroy, :order => "id DESC"
  has_many :meego_test_cases, :autosave => false,     :order => "id DESC"
  has_many :test_cases,       :class_name => "MeegoTestCase", :autosave => false,     :order => "id DESC"
  has_many :passed,           :class_name => "MeegoTestCase", :conditions => { :result => MeegoTestCase::PASS     }
  has_many :failed,           :class_name => "MeegoTestCase", :conditions => { :result => MeegoTestCase::FAIL     }
  has_many :na,               :class_name => "MeegoTestCase", :conditions => { :result => MeegoTestCase::NA       }
  has_many :measured,         :class_name => "MeegoTestCase", :conditions => { :result => MeegoTestCase::MEASURED }

  has_many :result_files,     :class_name => 'FileAttachment', :as => :attachable, :dependent => :destroy, :conditions => {:attachment_type => 'result_file'}
  has_many :attachments,      :class_name => 'FileAttachment', :as => :attachable, :dependent => :destroy, :conditions => {:attachment_type => 'attachment'}

  has_many :metrics, :dependent => :delete_all, :order => "id ASC"

  validates_presence_of :title, :testset, :product
  validates_presence_of :result_files
  validates_presence_of :author
  validates_presence_of :release, :profile
  validates             :tested_at, :date_time => true
  validate              :validate_profile_testset_and_product

  accepts_nested_attributes_for :features, :result_files, :metrics

  scope :published,  where(:published => true)
  scope :release,    lambda { |release| published.joins(:release).where(:releases => {:name => release}) }
  scope :profile,    lambda { |profile| published.joins(:profile).where(:profiles => {:name => profile}) }
  scope :testset,    lambda { |testset| published.where(:testset => testset.downcase) }
  scope :product_is, lambda { |product| published.where(:product => product.downcase) }

  include ReportSummary

  def self.latest
    published.order(:tested_at).last
  end

  #TODO: Throw away
  def month
    @month ||= tested_at.strftime("%B %Y")
  end

  def meego_test_session
    self
  end

  def self.fetch_fully(id)
    find(id, :include =>
         {:features =>
           {:meego_test_cases => [:measurements, :serial_measurements, :attachment, :feature, :meego_test_session]}
         })
  end

  def self.fetch_for_comparison(id)
    find(id, :include => {:meego_test_cases => [:feature, :meego_test_session]})
  end

  def self.testsets
    published.select("DISTINCT testset").order("testset").map(&:testset)
  end

  def self.popular_testsets(limit=3)
    published.select("testset").order("COUNT(testset) DESC").group(:testset).map(&:testset)
  end

  def self.products
    published.select("DISTINCT product as product").order("product").map(&:product)
  end

  def self.popular_products(limit=3)
    published.select("product as product").order("COUNT(product) DESC").
      group(:product).limit(limit).map(&:product)
  end

  def self.popular_build_ids(limit=3)
    published.select("build_id as build_id").order("COUNT(build_id) DESC").
      group(:build_id).limit(limit).map { |row| row.build_id.humanize }
  end

  def prev_summary
    prev_session
  end

  def self.load_case_counts_for_reports!(reports)
    result_counts = MeegoTestCase.select([:meego_test_session_id, :result, :count]).
      where(:meego_test_session_id => reports).group(:meego_test_session_id, :result).count(:result)

    reports.map! do |report|
      # Calculate NA value separately since we need to include CUSTOM to it. Either one may be nil
      na     = result_counts[[report.id, MeegoTestCase::NA]]
      custom = result_counts[[report.id, MeegoTestCase::CUSTOM]]
      if not custom.nil?
        na = if na.nil? then custom else na + custom end
      end

      report.total_passed   = result_counts[[report.id, MeegoTestCase::PASS]]
      report.total_failed   = result_counts[[report.id, MeegoTestCase::FAIL]]
      report.total_na       = na
      report.total_measured = result_counts[[report.id, MeegoTestCase::MEASURED]]
      report.total_cases    = report.total_passed + report.total_failed + report.total_na + report.total_measured
      report
    end
  end

  ###############################################
  # Test session navigation                     #
  ###############################################
  def prev_session
    return @prev_session unless @prev_session.nil? and @has_prev.nil?
    tested = tested_at || Time.now
    created = created_at || Time.now

    @prev_session = MeegoTestSession.find(:first, :conditions => [
        "(tested_at < ? OR tested_at = ? AND created_at < ?) AND profile_id = ? AND testset = ? AND product = ? AND published = ? AND release_id = ?", tested, tested, created, profile.try(:id), testset.downcase, product.downcase, true, release_id
    ],
                          :order => "tested_at DESC, created_at DESC", :include =>
         [{:features => :meego_test_cases}, {:meego_test_cases => :feature}])

    @has_prev = !@prev_session.nil?
    @prev_session
  end

  def next_session
    return @next_session unless @next_session.nil? and @has_next.nil?
    @next_session = MeegoTestSession.find(:first, :conditions => [
        "(tested_at > ? OR tested_at = ? AND created_at > ?) AND profile_id = ? AND testset = ? AND product = ? AND published = ? AND release_id = ?", tested_at, tested_at, created_at, profile.try(:id), testset.downcase, product.downcase, true, release_id
    ],
                          :order => "tested_at ASC, created_at ASC", :include =>
         [{:features => :meego_test_cases}, {:meego_test_cases => :feature}])

    @has_next = !@next_session.nil?
    @next_session
  end

  ###############################################
  # Utility methods for viewing a report        #
  ###############################################
  def formatted_date
    tested_at ? tested_at.strftime("%Y-%m-%d") : 'n/a'
  end

  def nft_sets
    features.select &:has_nft?
  end

  def non_nft_features
    features.select &:has_non_nft?
  end

  def test_case_by_name(feature_key, name)
    @test_case_hash ||= meego_test_cases.to_nested_hash [:feature_key, :name]
    @test_case_hash[feature_key][name] unless @test_case_hash[feature_key].nil?
  end

  def metric_by_name(group_name, name)
    grouped_metrics[group_name].select {|m| m[:name] == name} .first unless grouped_metrics[group_name].nil?
  end

  def grouped_metrics
    # Group by group_name
    @metrics_groups ||= metrics.group_by {|m| m[:group_name]}
  end

  def charted_metrics
    @charted_metrics ||= metrics.where("chart = ?", true)
  end

  ###############################################
  # Chart visualization methods                 #
  ###############################################
  def summary_data
    data = Graph::Data.new
    data.passed    = passed   = []
    data.failed    = failed   = []
    data.na        = na       = []
    data.measured  = measured = []
    data.labels    = labels   = []

    prev = prev_session
    if prev
      pp = prev.prev_session
      if pp
        passed    << pp.total_passed
        failed    << pp.total_failed
        na        << pp.total_na
        measured  << pp.total_measured
        labels    << pp.formatted_date
      else
        passed    << 0
        failed    << 0
        na        << 0
        measured  << 0
        labels    << ""
      end

      passed    << prev.total_passed
      failed    << prev.total_failed
      na        << prev.total_na
      measured  << prev.total_measured
      labels    << prev.formatted_date
    else
      passed    << 0
      failed    << 0
      na        << 0
      measured  << 0
      labels    << ""
    end

    passed    << total_passed
    failed    << total_failed
    na        << total_na
    measured  << total_measured
    labels    << "Current"

    data
  end

  def max_feature_cases
    features.map{|item| item.total_cases}.max
  end

  def non_empty_features
    features.select{|feature| feature.total_cases > 0}
  end

  def small_graph_img_tag(max_cases)
    html_graph(total_passed, total_failed, total_na, max_cases)
  end

  ###############################################
  # Text data html formatting                   #
  ###############################################
  def objective_html
    txt = objective_txt
    if txt == ""
      "No objective filled in yet"
    else
      MeegoTestReport::format_txt(txt)
    end
  end

  def tested_at_html
    tested_at.strftime("%Y-%m-%d")
  end

  def tested_at_txt
    tested_at.strftime("%Y-%m-%d")
  end

  def build_html
    txt = build_txt
    if txt == ""
      "No build details filled in yet"
    else
      MeegoTestReport::format_txt(txt)
    end
  end

  def environment_html
    txt = environment_txt
    if txt == ""
      "No environment description filled in yet"
    else
      MeegoTestReport::format_txt(txt)
    end
  end

  def qa_summary_html
    txt = qa_summary_txt
    if txt == ""
      "No quality summary filled in yet"
    else
      MeegoTestReport::format_txt(txt)
    end
  end

  def issue_summary_html
    txt = issue_summary_txt
    if txt == ""
      "No issue summary filled in yet"
    else
      MeegoTestReport::format_txt(txt)
    end
  end

  def patches_included_html
    txt = patches_included_txt
    if txt == ""
      "Included patches not filled in yet"
    else
      MeegoTestReport::format_txt(txt)
    end
  end

  def validate_profile_testset_and_product
    # \A and \z instead of ^ and $ cause multiline strings to fail validation.
    # And for the record: at least these characters break the navigation:
    # . % \ / (yes, dot is there as well for some oddball reason)
    allowed = /\A[\w\ \-:;,\(\)]+\z/

    errors.add :testset, "Incorrect test set. Please use only characters A-Z, a-z, 0-9, spaces and these special characters: , : ; - _ ( )" unless testset.match(allowed)
    errors.add :product, "Incorrect product. Please use only characters A-Z, a-z, 0-9, spaces and these special characters: , : ; - _ ( )"  unless product.match(allowed)
  end

  def generate_defaults!
    time                 = tested_at || Time.now
    self.title           ||= "%s Test Report: %s %s %s" % [profile.name, product_label, testset_label, time.strftime('%Y-%m-%d')]
    self.environment_txt = "* Product: " + product if self.environment_txt.empty?
  end

  def format_date
    tested_at.strftime("%d.%m")
  end

  def format_table_date
    tested_at.strftime(APP_CONFIG['table_date_format'])
  end

  def format_year
    tested_at.strftime("%Y")
  end

  RESULT_NAMES = {"fail"     => MeegoTestCase::FAIL,
                  "na"       => MeegoTestCase::NA,
                  "pass"     => MeegoTestCase::PASS,
                  "measured" => MeegoTestCase::MEASURED}

  RESULT_CODES = RESULT_NAMES.invert

  #TODO: move to test case?
  def self.map_result(result)
    result = RESULT_CODES[MeegoTestCase::NA] if result.downcase == "n/a"

    status_code = RESULT_NAMES[result.downcase]
    if status_code
      [status_code, nil]
    else
      [MeegoTestCase::CUSTOM, CustomResult.find_by_name(result)]
    end
  end

  def self.result_as_string(result)
    RESULT_CODES[result] || RESULT_CODES[MeegoTestCase::NA]
  end

  # TODO: Test cases are lost if saving fails
  def update_report_result(user, params, published = true)
    # Add required attributes to params
    params.merge!(
      :release => self.release,
      :profile => self.profile,
      :testset => self.testset,
      :product => self.product,
      :author  => self.author
    )

    tmp = ReportFactory.new.build(params)
    parsing_errors = tmp.errors.to_hash

    if !parsing_errors.empty?
      return "Request contained invalid files: " + parsing_errors[:result_files].join(',')
    end

    if not tmp.valid?
      return tmp.errors.to_hash
    end

    user.update_attribute(:default_target, self.profile.name) if self.profile.name.present?
    self.editor    = user
    self.published = published

    @result_files = tmp.result_files
    self.features.clear
    self.meego_test_cases.clear
    tmp.features.each do |feature|
      feature.meego_test_cases.each { |tc| tc.meego_test_session = self }
    end
    self.features = tmp.features
    self.meego_test_cases = tmp.meego_test_cases
    return nil
  end

  def merge_result_files!(files)
    unless files.present?
      errors.add :result_files, "No result files."
      return self
    end

    files.each do |f|
      unless f.respond_to?(:original_filename)
        errors.add :result_files, "Invalid file: #{f.to_s}."
        return self
      end
    end

    begin
      new_data = ReportFactory.new.parse_results(files)
    rescue ParseError => e
      errors.add :result_files, "Invalid file: #{e.message}"
      return self
    end

    logger.info "new_data: #{new_data.inspect}"
    merge!(new_data)
  end

  def merge!(report_hash)
    current_features = features.index_by &:name
    current_metrics  = metrics.index_by {|m| "#{m[:group_name]}_#{m[:name]}"}

    to_update, to_create = report_hash[:features_attributes].
                           partition {|fh| current_features.has_key? fh[:name]}

    to_update.each { |fh| current_features[fh[:name]].merge! fh }

    to_create.each { |fh| features.create fh }

    # Then metrics,given that we have any
    unless report_hash[:metrics_attributes].nil?
      to_update, to_create = report_hash[:metrics_attributes].
                             partition {|m| current_metrics.has_key? "#{m[:group_name]}_#{m[:name]}"}

      to_update.each do |m|
        metric_by_name(m[:group_name], m[:name]).update_attributes(m)
      end

      to_create.each {|m| metrics.create m}
    end

    # Store only if there are no errors and the session is valid.
    # Error count is checked separately because the model may be
    # valid, and calling valid? would then clear the errors that
    # have been added for other reasons programmatically.
    # The check in general needs to be done since due to some oddity
    # the result_files ARE saved even if session.save wouldn't be called
    self.result_files += report_hash[:result_files] || [] if self.errors.empty? && self.valid?

    self
  end
end
