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
require 'tempfile'
require 'fileutils'
require 'cache_helper'

class UploadController < ApplicationController
  include CacheHelper

  cache_sweeper :meego_test_session_sweeper, :only => [:upload]
  before_filter :authenticate_user!

  def upload_form
    new_report = {}
    [:release_version, :target, :testset, :product].each do |key|
      new_report[key] = params[key] if params[key]
    end

    new_report[:release] = new_report[:release].downcase if new_report[:release]
    new_report[:target] ||= new_report[:target].downcase if new_report[:target]
    new_report[:target] ||= TargetLabel.targets.first.downcase
    @test_session = MeegoTestSession.new(new_report)
    @test_session.release = Release.find_by_label(new_report[:release_version]) || Release.latest

    @release_versions = Release.in_sort_order.map { |release| release.label }
    @targets          = TargetLabel.targets.map {|target| target.downcase}
    @testsets         = MeegoTestSession.release(@selected_release_version).testsets
    @products         = MeegoTestSession.release(@selected_release_version).popular_products
    @build_ids        = MeegoTestSession.release(@selected_release_version).popular_build_ids

    @no_upload_link = true
  end

  def upload_report
    file = filestream_from_qq_param

    attachment = FileAttachment.create! :file => file, :attachment_type => :result_file

    render :json => { :ok => '1', :attachment_id => attachment.id }
  end

  def upload_attachment
    file = filestream_from_qq_param

    session = MeegoTestSession.find(params[:id])
    session.attachments.create(:file => file)
    @editing = true

    expire_caches_for(session)
    # full file name of template has to be given because flash uploader can pass header HTTP_ACCEPT: text/*
    # file is not found because render :formats=>[:"text/*"]
    html_content = render_to_string :partial => 'reports/file_attachment_list.html.slim', :locals => {:report => session, :files => session.attachments}
    render :json => { :ok => '1', :html_content => html_content}
  end

  def upload
    params[:meego_test_session][:result_files] = FileAttachment.where(:id => params.delete(:drag_n_drop_attachments))

    @test_session = ReportFactory.new.build(params[:meego_test_session])
    @test_session.author = current_user
    @test_session.editor = current_user

    if @test_session.errors.empty? and @test_session.save
      redirect_to preview_report_path(@test_session)
    else
      @release_versions = Release.all.map { |release| release.label }
      @targets          = TargetLabel.targets
      @testsets         = MeegoTestSession.release(@selected_release_version).testsets
      @products         = MeegoTestSession.release(@selected_release_version).popular_products
      @build_ids        = MeegoTestSession.release(@selected_release_version).popular_build_ids
      render :upload_form
    end
  end

  private

  def filestream_from_qq_param
    if request['qqfile'].respond_to? 'original_filename'
      return request['qqfile']
    else
      f = StringIO.new(env['rack.input'].read())
      f.original_filename = request['qqfile']
      return f
    end
  end
end
