#
# This file is part of meego-test-reports
#
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
#
# Authors: Sami Hangaslammi <sami.hangaslammi@leonidasoy.fi>
#          Jarno Keskikangas <jarno.keskikangas@leonidasoy.fi>
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

require 'digest/sha1'
require 'open-uri'
require 'drag_n_drop_uploaded_file'
require 'file_storage'
require 'report_comparison'
require 'cache_helper'
require 'iconv'
require 'net/http'
require 'net/https'

module AjaxMixin
  def remove_attachment
    @preview_id   = params[:id].to_i
    @test_session = MeegoTestSession.find(@preview_id)
    files         = FileStorage.new()
    files.remove_file(@test_session, params[:name])
    render :json => {:ok => '1'}
  end

  def update_title
    @preview_id   = params[:id].to_i
    @test_session = MeegoTestSession.find(@preview_id)

    field         = params[:meego_test_session]
    field         = field.keys()[0]
    @test_session.update_attribute(field, params[:meego_test_session][field])
    @test_session.updated_by(current_user)
    expire_caches_for(@test_session)
    expire_index_for(@test_session)

    render :text => "OK"
  end

  def update_case_comment
    case_id  = params[:id]
    comment  = params[:comment]
    testcase = MeegoTestCase.find(case_id)
    testcase.update_attribute(:comment, comment)

    test_session = testcase.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session)

    render :text => "OK"
  end

  def update_case_result
    case_id  = params[:id]
    result   = params[:result]
    testcase = MeegoTestCase.find(case_id)
    testcase.update_attribute(:result, result.to_i)

    test_session = testcase.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session, true)

    render :text => "OK"
  end

  def update_txt
    @preview_id   = params[:id]
    @test_session = MeegoTestSession.find(@preview_id)

    field         = params[:meego_test_session]
    field         = field.keys()[0]
    @test_session.update_attribute(field, params[:meego_test_session][field])
    @test_session.updated_by(current_user)
    expire_caches_for(@test_session)

    sym = field.sub("_txt", "_html").to_sym

    render :text => @test_session.send(sym)
  end


  def update_tested_at
    @preview_id = params[:id]

    if @preview_id
      @test_session = MeegoTestSession.find(@preview_id)

      field         = params[:meego_test_session].keys.first
      logger.warn("Updating #{field} with #{params[:meego_test_session][field]}")
      @test_session.update_attribute(field, params[:meego_test_session][field])
      @test_session.updated_by(current_user)

      expire_caches_for(@test_session)
      expire_index_for(@test_session)

      render :text => @test_session.tested_at.strftime('%d %B %Y')
    else
      logger.warn "WARNING: report id #{@preview_id} not found"
    end
  end

  def update_category
    @preview_id = params[:id]

    if @preview_id
      @test_session = MeegoTestSession.find(@preview_id)

      data = params[:meego_test_session]
      data.keys.each do |key|
        @test_session.update_attribute(key, data[key])
      end
      @test_session.updated_by(current_user)

      expire_caches_for(@test_session)
      expire_index_for(@test_session)

      render :text => @test_session.tested_at.strftime('%d %B %Y')
    else
      logger.warn "WARNING: report id #{@preview_id} not found"
    end
  end

  def update_feature_comment
    set_id = params[:id]
    comments = params[:comment]
    testset = MeegoTestSet.find(set_id)
    testset.update_attribute(:comments, comments)

    test_session = testset.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session)

    render :text => "OK"
  end

  def update_feature_grading
    set_id = params[:id]
    grading = params[:grading]
    testset = MeegoTestSet.find(set_id)
    testset.update_attribute(:grading, grading)
 
    test_session = testset.meego_test_session
    test_session.updated_by(current_user)
    expire_caches_for(test_session)

    render :text => "OK"
  end

end

class ReportsController < ApplicationController
  include AjaxMixin
  include CacheHelper
  
  before_filter :authenticate_user!, :except => ["view", "print", "compare", "fetch_bugzilla_data"]

  #caches_page :print
  #caches_page :index, :upload_form, :email, :filtered_list
  #caches_page :view, :if => proc {|c|!c.just_published?}
  caches_action :fetch_bugzilla_data,
                :cache_path => Proc.new { |controller| controller.bugzilla_cache_key },
                :expires_in => 1.hour

  def preview
    @preview_id = session[:preview_id] || params[:id]
    @editing    = true
    @wizard     = true

    if @preview_id
      @test_session   = MeegoTestSession.fetch_fully(@preview_id)
      @report         = @test_session
      @no_upload_link = true

      @report         = @test_session
      @release_versions = VersionLabel.all.map { |release| release.label }
      @targets = MeegoTestSession.targets
      @testtypes = MeegoTestSession.release(@selected_release_version).testtypes
      @hardware = MeegoTestSession.release(@selected_release_version).popular_hardwares

      @raw_result_files = @test_session.raw_result_files

      render :layout => "report"
    else
      redirect_to :controller => 'upload', :action => :upload_form
    end
  end

  def publish
    report_id    = params[:report_id]
    test_session = MeegoTestSession.fetch_fully(report_id)
    test_session.update_attribute(:published, true)

    expire_caches_for(test_session, true)
    expire_index_for(test_session)

    redirect_to :action          => 'view',
                :id              => report_id,
                :release_version => test_session.release_version,
                :target          => test_session.target,
                :testtype        => test_session.testtype,
                :hardware       => test_session.hardware
  end

  def view
    if @report_id = params[:id].try(:to_i)
      preview_id = session[:preview_id]

      if preview_id == @report_id
        session[:preview_id] = nil
        @published           = true
      else
        @published = false
      end

      @test_session = MeegoTestSession.fetch_fully(@report_id)

      return render_404 unless @selected_release_version.downcase.eql? @test_session.release_version.downcase

      @history = history(@test_session.prev_session)

      @target    = @test_session.target
      @testtype  = @test_session.testtype
      @hardware = @test_session.hardware

      @report    = @test_session
      @files = FileStorage.new().list_files(@test_session) or []
      @raw_result_files = @test_session.raw_result_files
      @editing = false
      @wizard  = false

      @nft_trends = nil
      if @test_session.has_nft?
        @nft_trends = NftHistory.new().session_measurement_csv_trend(@test_session)
      end

      render :layout => "report"
    else
      redirect_to :action => :index
    end
  end

  def print
    if @report_id = params[:id].try(:to_i)
      @test_session = MeegoTestSession.fetch_fully(@report_id)

      @report       = @test_session
      @editing      = false
      @files = FileStorage.new().list_files(@test_session) or []
      @wizard = false
      @email  = true

      render :layout => "report"
    else
      redirect_to :action => :index
    end
  end

  def edit
    @editing = true
    @wizard  = false

    if id = params[:id].try(:to_i)
      @test_session   = MeegoTestSession.fetch_fully(id)
      @report         = @test_session
      @release_versions = VersionLabel.all.map { |release| release.label }
      @targets = MeegoTestSession.targets
      @testtypes = MeegoTestSession.release(@selected_release_version).testtypes
      @hardware = MeegoTestSession.release(@selected_release_version).popular_hardwares
      @no_upload_link = true
      @files = FileStorage.new().list_files(@test_session) or []
      @raw_result_files = @test_session.raw_result_files

      render :layout => "report"
    else
      redirect_to :action => :index
    end
  end

  def compare
    @comparison = ReportComparison.new()
    @release_version = params[:release_version]
    @target = params[:target]
    @testtype = params[:testtype]
    @comparison_testtype = params[:comparetype]    
    @compare_cache_key = "compare_page_#{@release_version}_#{@target}_#{@testtype}_#{@comparison_test_type}"

    MeegoTestSession.published_hwversion_by_release_version_target_test_type(@release_version, @target, @testtype).each{|hardware|
        left = MeegoTestSession.by_release_version_target_test_type_product(@release_version, @target, @testtype, hardware.hardware).first
        right = MeegoTestSession.by_release_version_target_test_type_product(@release_version, @target, @comparison_testtype, hardware.hardware).first
        @comparison.add_pair(hardware.hardware, left, right)
    }
    @groups = @comparison.groups
    render :layout => "report"
  end

  def fetch_bugzilla_data
    ids       = params[:bugids]

    uri = BUGZILLA_CONFIG['uri'] + ids.join(',')

    content = ""
    if not BUGZILLA_CONFIG['proxy_server'].nil?
      @http = Net::HTTP.Proxy(BUGZILLA_CONFIG['proxy_server'], BUGZILLA_CONFIG['proxy_port']).new(BUGZILLA_CONFIG['server'], BUGZILLA_CONFIG['port'])
    else
      @http = Net::HTTP.new(BUGZILLA_CONFIG['server'], BUGZILLA_CONFIG['port'])
    end

    @http.use_ssl = BUGZILLA_CONFIG['use_ssl']
    @http.start() {|http|
      req = Net::HTTP::Get.new(uri)
      if not BUGZILLA_CONFIG['http_username'].nil?
        req.basic_auth BUGZILLA_CONFIG['http_username'], BUGZILLA_CONFIG['http_password']
      end
      response = http.request(req)
      content = response.body
    }

    # XXX: bugzilla seems to encode its exported csv to utf-8 twice
    # so we convert from utf-8 to iso-8859-1, which is then interpreted
    # as utf-8
     render :text => Iconv.iconv("iso-8859-1", "utf-8", content), :content_type => "text/csv"

  end

  def delete
    id           = params[:id]

    test_session = MeegoTestSession.find(id)

    expire_caches_for(test_session, true)
    expire_index_for(test_session)

    test_session.destroy

    redirect_to :controller => :index, :action => :index
  end

  protected

  def bugzilla_cache_key
    h = Digest::SHA1.hexdigest params.to_hash.to_a.map{|k,v| if v.respond_to?(:join) then k+v.join(",") else k+v end}.join(';')
    "bugzilla_#{h}"
  end

  def history(s)
    h = []
    while h.size < 5 
      h << s
      s = s.prev_session if s
    end
    return h
  end

  def just_published?
    @published
  end
end
