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
require 'lib/array_nested_hashing'

#noinspection Rails3Deprecated
class MeegoTestSession < ActiveRecord::Base
  include Trimmer
  include Graph
  include MeasurementUtils
  include CacheHelper

  has_many :features, :dependent => :destroy, :order => "id DESC"
  has_many :meego_test_cases, :autosave => false, :order => "id DESC"
  has_many :result_files, :class_name => 'FileAttachment', :as => :attachable, :dependent => :destroy, :conditions => {:attachment_type => 'result_file'}
  has_many :attachments,  :class_name => 'FileAttachment', :as => :attachable, :dependent => :destroy, :conditions => {:attachment_type => 'attachment'}

  has_many :passed, :class_name => "MeegoTestCase", :conditions => "result = #{MeegoTestCase::PASS}"
  has_many :failed, :class_name => "MeegoTestCase", :conditions => "result = #{MeegoTestCase::FAIL}"
  has_many :na, :class_name => "MeegoTestCase", :conditions => "result = #{MeegoTestCase::NA}"

  belongs_to :author, :class_name => "User"
  belongs_to :editor, :class_name => "User"

  belongs_to :release

  validates_presence_of :title, :target, :testset, :product
  validates_presence_of :result_files
  validates_presence_of :author

  validates :tested_at, :date_time => true

  validate :validate_labels
  validate :validate_type_hw

  accepts_nested_attributes_for :features, :result_files

  before_save :force_testset_product_names

  scope :published,  where(:published => true)
  scope :release,    lambda { |release| published.joins(:release).where(:releases => {:normalized => release.downcase}) }
  scope :profile,    lambda { |profile| published.where(:target => profile.downcase) }
  scope :testset,    lambda { |testset| published.where(:testset => testset.downcase) }
  scope :product_is, lambda { |product| published.where(:product => product.downcase) }

  RESULT_FILES_DIR = "public/reports"
  INVALID_RESULTS_DIR = "public/reports/invalid_files"

  include ReportSummary

  def meego_test_session
    self
  end

  def self.latest
    published.order(:tested_at).last
  end

  def month
    @month ||= tested_at.strftime("%B %Y")
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

  def target=(target)
    target = target.try(:downcase)
    write_attribute(:target, target)
  end

  def target
    read_attribute(:target).try(:capitalize)
  end

  def build_id_txt=(build_id)
    write_attribute(:build_id, build_id)
  end

  def build_id_txt
    s = read_attribute(:build_id)
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
      report.total_passed = result_counts[[report.id, MeegoTestCase::PASS]]
      report.total_failed = result_counts[[report.id, MeegoTestCase::FAIL]]
      report.total_na     = result_counts[[report.id, MeegoTestCase::NA]]
      report.total_cases  = report.total_passed + report.total_failed + report.total_na
      report
    end
  end

  def self.filters_exist?(target, testset, product)
    return true if target.blank? and testset.blank? and product.blank?

    filters_exist = false

    if target.present?
      filters_exist = find_by_target(target.downcase).present?

      if testset.present?
        filters_exist &= find_by_testset(testset.downcase).present?
      end

      if testset.present? && product.present?
        filters_exist &= find_by_product(product.downcase).present?
      end
    end

    return filters_exist
  end

  #TODO: Throw away and use scopes
  class << self
    def by_release_version_target_testset_product(release_version, target, testset, product, order_by = "tested_at DESC, id DESC", limit = nil)
      target    = target.downcase
      testset  = testset.downcase
      product = product.downcase
      published.where("releases.normalized" => release_version.downcase, :target => target, :testset => testset, :product => product).joins(:release).order(order_by).limit(limit)
    end

    def published_by_release_version_target_testset(release_version, target, testset, order_by = "tested_at DESC, id DESC", limit = nil)
      target   = target.downcase
      testset = testset.downcase
      published.where("releases.normalized" => release_version.downcase, :target => target, :testset => testset).joins(:release).order(order_by).limit(limit)
    end

    def published_hwversion_by_release_version_target_testset(release_version, target, testset)
      target   = target.downcase
      testset = testset.downcase
      published.where("releases.normalized" => release_version.downcase, :target => target, :testset => testset).select("DISTINCT product").joins(:release).order("product")
    end

    def published_by_release_version_target(release_version, target, order_by = "tested_at DESC, id DESC", limit = nil)
      target = target.downcase
      published.where("releases.normalized" => release_version.downcase, :target => target).joins(:release).order(order_by).limit(limit)
    end

    def published_by_release_version(release_version, order_by = "tested_at DESC", limit = nil)
      published.where("releases.normalized" => release_version.downcase).joins(:release).order(order_by).limit(limit)
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
        "(tested_at < ? OR tested_at = ? AND created_at < ?) AND target = ? AND testset = ? AND product = ? AND published = ? AND release_id = ?", tested, tested, created, target.downcase, testset.downcase, product.downcase, true, release_id
    ],
                          :order => "tested_at DESC, created_at DESC", :include =>
         [{:features => :meego_test_cases}, {:meego_test_cases => :feature}])

    @has_prev = !@prev_session.nil?
    @prev_session
  end

  def next_session
    return @next_session unless @next_session.nil? and @has_next.nil?
    @next_session = MeegoTestSession.find(:first, :conditions => [
        "(tested_at > ? OR tested_at = ? AND created_at > ?) AND target = ? AND testset = ? AND product = ? AND published = ? AND release_id = ?", tested_at, tested_at, created_at, target.downcase, testset.downcase, product.downcase, true, release_id
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

  ###############################################
  # Chart visualization methods                 #
  ###############################################
  def summary_data
    data = Graph::Data.new
    data.passed = passed = []
    data.failed = failed = []
    data.na     = na     = []
    data.labels = labels = []

    prev = prev_session
    if prev
      pp = prev.prev_session
      if pp
        passed << pp.total_passed
        failed << pp.total_failed
        na     << pp.total_na
        labels << pp.formatted_date
      else
        passed << 0
        failed << 0
        na     << 0
        labels << ""
      end

      passed << prev.total_passed
      failed << prev.total_failed
      na     << prev.total_na
      labels << prev.formatted_date
    else
      passed << 0
      failed << 0
      na     << 0
      labels << ""
    end

    passed << total_passed
    failed << total_failed
    na     << total_na
    labels << "Current"

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

  # Check that the target and release_version given as parameters
  # exist in label tables. Test session tables allow anything, but
  # if using other than what's in the label tables, the results
  # won't show up
  def validate_labels
    if target.blank?
      errors.add :target, "can't be blank"
    else
      label = TargetLabel.find(:first, :conditions => {:normalized => target.downcase})
      if not label
        valid_targets = TargetLabel.labels.join(",")
        errors.add :target, "Incorrect target '#{target}'. Valid ones are #{valid_targets}."
      end
    end
  end

  # Validate user entered test set and hw product. If all characters are
  # allowed users may enter characters that break the functionality. Thus,
  # restrict the allowed subset to certainly safe
  def validate_type_hw
    # \A and \z instead of ^ and $ cause multiline strings to fail validation.
    # And for the record: at least these characters break the navigation:
    # . % \ / (yes, dot is there as well for some oddball reason)
    allowed = /\A[\w\ \-:;,\(\)]+\z/

    if not testset.match(allowed)
      errors.add :testset, "Incorrect test set. Please use only characters A-Z, a-z, 0-9, spaces and these special characters: , : ; - _ ( )"
    end

    if not product.match(allowed)
      errors.add :product, "Incorrect product. Please use only characters A-Z, a-z, 0-9, spaces and these special characters: , : ; - _ ( )"
    end
  end

  def force_testset_product_names
    write_attribute :testset, testset_label
    write_attribute :product, product_label
  end

  def testset_label
    @testset_label = self.class.persistent_label_for(:testset, testset) if @testset_label.nil? or testset.casecmp(@testset_label) != 0
    @testset_label
  end

  def product_label
    @product_label = self.class.persistent_label_for(:product, product) if @product_label.nil? or product.casecmp(@product_label) != 0
    @product_label
  end

  def self.persistent_label_for(attribute, name)
    session = MeegoTestSession.select(attribute).find(:first, :conditions => {attribute => name})
    session.present? ? session.send(attribute) : name
  end


  def generate_defaults!
    time                 = tested_at || Time.now
    self.title           ||= "%s Test Report: %s %s %s" % [target, product_label, testset_label, time.strftime('%Y-%m-%d')]
    self.environment_txt = "* Product: " + product if self.environment_txt.empty?
  end

  def format_date
    tested_at.strftime("%d.%m")
  end

  def format_year
    tested_at.strftime("%Y")
  end

  def self.map_result(result)
    result = result.downcase
    if result == "pass"
      1
    elsif result == "fail"
      -1
    else
      0
    end
  end

  def sanitize_filename(filename)
    filename.gsub(/[^\w\.\_\-]/, '_')
  end

  def valid_filename_extension?(filename)
    if filename =~ /\.csv$/i or filename =~ /\.xml$/i
      return true
    else
      errors.add :result_files, "You can only upload files with the extension .xml or .csv"
      return false
    end
  end

  ###############################################
  # For encapsulating the release_version          #
  ###############################################
  def release_version=(release_version)
    release = Release.where(:normalized => release_version.downcase)
    self.release = release.first
  end

  def release_version
    if self.release
      return self.release.label
    else
      return nil
    end
  end

  def generate_file_destination_path(original_filename)
    datepart = Time.now.strftime("%Y%m%d")
    dir      = File.join(RESULT_FILES_DIR, datepart)
    dir      = File.join(INVALID_RESULTS_DIR, datepart) if !errors.empty? #store invalid results data for debugging purposes

    FileUtils.mkdir_p(dir)

    filename     = ("%06i-" % Time.now.usec) + sanitize_filename(original_filename)
    path_to_file = File.join(dir, filename)
  end

  def update_report_result(user, params, published = true)
    tmp = ReportFactory.new.build(params)
    parsing_errors = tmp.errors[:result_files]

    user.update_attribute(:default_target, self.target) if self.target.present?
    self.editor    = user
    self.published = published

    if !parsing_errors.empty?
      return parsing_errors.join(',')
    else
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
  end

  private

  def create_release
    verlabel = Release.find(:first, :conditions => {:normalized => release_version.downcase})
    if verlabel
      self.release = verlabel
      save
    else
      verlabel = Release.new(:label => release_version, :normalized => release_version.downcase)
      verlabel.save
    end
  end

  def create_target_label
    tarlabel = TargetLabel.find(:first, :conditions => {:normalized => target.downcase})
    if tarlabel
      self.target = tarlabel.label
      save
    else
      tarlabel = TargetLabel.new(:label => target, :normalized => target.downcase)
      tarlabel.save
    end
  end

  def create_labels
    create_release && create_target_label
  end

end
