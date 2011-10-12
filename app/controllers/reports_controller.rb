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
require 'file_storage'
require 'report_comparison'
require 'cache_helper'
require 'iconv'
require 'net/http'
require 'net/https'
require 'report_exporter'

class ReportsController < ApplicationController
  include CacheHelper
  layout        'report'
  before_filter :authenticate_user!,         :except => [:index, :index_latest, :show, :print, :compare]
  before_filter :validate_path_params,       :only   => [:show, :print]
  cache_sweeper :meego_test_session_sweeper, :only   => [:update, :delete, :publish]

  def index
    @index_model = Index.find_by_release(release)
    @show_rss = true
    render :layout => "application"
  end

  def index_latest
    @index_model = Index.find_by_lateset_release(release)
    @show_rss = true
    render :layout => "application"
  end

  def preview
    populate_report_fields
    populate_edit_fields
    @editing          = true
    @wizard           = true
    @no_upload_link   = true
    @report_show      = ReportShow.new(MeegoTestSession.find(params[:id]))
  end

  def publish
    report = MeegoTestSession.find(params[:id])
    report.update_attribute(:published, true)

    flash[:notice] = "Your report has been successfully published"
    redirect_to show_report_path(report.release.name, report.target, report.testset, report.product, report)
  end

  def show
    populate_report_fields
    @history      = history(@report, 5)
    @build_diff   = build_diff(@report, 4)
    @report_show  = ReportShow.new(MeegoTestSession.find(params[:id]), @build_diff)
  end

  def print
    populate_report_fields
    @build_diff   = []
    @email        = true
    @report_show  = ReportShow.new(MeegoTestSession.find(params[:id]))
  end

  def edit
    populate_report_fields
    populate_edit_fields
    @editing        = true
    @no_upload_link = true
    @report_show    = ReportShow.new(MeegoTestSession.find(params[:id]))
  end

  def update
    @report = MeegoTestSession.find(params[:id])
    @report.update_attributes(params[:report]) # Doesn't check for failure
    @report.update_attribute(:editor, current_user)

    #TODO: Fix templates so that normal 'head :ok' response is enough
    render :text => @report.tested_at.strftime('%d %B %Y')
  end

  def destroy
    report = MeegoTestSession.find(params[:id])
    report.destroy
    redirect_to root_path
  end

  #TODO: This should be in comparison controller
  def compare
    @comparison = ReportComparison.new()
    @release_version = params[:release_version]
    @target = params[:target]
    @testset = params[:testset]
    @comparison_testset = params[:comparetype]
    @compare_cache_key = "compare_page_#{@release_version}_#{@target}_#{@testset}_#{@comparison_testset}"

    MeegoTestSession.published_hwversion_by_release_version_target_testset(@release_version, @target, @testset).each{|product|
        left  = MeegoTestSession.release(@release_version).profile(@target).testset(@testset).product(product.product).first
        right = MeegoTestSession.release(@release_version).profile(@target).testset(@comparison_testset).product(product.product).first
        @comparison.add_pair(product.product, left, right)
    }
    @groups = @comparison.groups
    render :layout => "report"
  end

  private

  def validate_path_params
    if params[:release_version]
      # Raise ActiveRecord::RecordNotFound if the report doesn't exist
      MeegoTestSession.release(release.name).profile(profile).testset(testset).product_is(product).find(params[:id])
    end
  end

  def populate_report_fields
    @report = MeegoTestSession.fetch_fully(params[:id])
    @nft_trends   = NftHistory.new(@report) if @report.has_nft?
  end

  def populate_edit_fields
    @build_diff       = []
    @release_versions = Release.in_sort_order.map { |release| release.name }
    @targets          = TargetLabel.targets
    @testsets         = MeegoTestSession.release(release.name).testsets
    @products         = MeegoTestSession.release(release.name).popular_products
    @build_ids        = MeegoTestSession.release(release.name).popular_build_ids
  end

  protected

  #TODO: These should be somewhere else..
  def history(s, cnt)
    MeegoTestSession.where("(tested_at < '#{s.tested_at}' OR tested_at = '#{s.tested_at}' AND created_at < '#{s.created_at}') AND target = '#{s.target.downcase}' AND testset = '#{s.testset.downcase}' AND product = '#{s.product.downcase}' AND published = 1 AND release_id = #{s.release_id}").
        order("tested_at DESC, created_at DESC").limit(cnt).
        includes([{:features => :meego_test_cases}, {:meego_test_cases => :feature}])
  end

  def build_diff(s, cnt)
    sessions = MeegoTestSession.published.profile(s.target).testset(s.testset).product_is(s.product).
        where("release_id = #{s.release_id} AND build_id < '#{s.build_id}' AND build_id != ''").
        order("build_id DESC, tested_at DESC, created_at DESC")

    latest = []
    sessions.each do |session|
      latest << session if (latest.empty? or session.build_id != latest.last.build_id)
    end

    diff = MeegoTestSession.where(:id => latest).
        order("build_id DESC, tested_at DESC, created_at DESC").limit(cnt).
        includes([{:features => :meego_test_cases}, {:meego_test_cases => :feature}])
  end
end
