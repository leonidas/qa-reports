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
    [:testset, :product].each do |key|
      new_report[key] = params[key] if params[key]
    end

    @test_session = MeegoTestSession.new(new_report)
    @test_session.release = Release.find_by_name(params[:release_version])
    @test_session.profile = profile || Profile.first

    set_suggestions

    @profiles  = Profile.names

    @no_upload_link = true
  end

  def upload_report
    file = filestream_from_qq_param

    attachment = FileAttachment.create! :file => file, :attachment_type => :result_file

    render :json => { :ok => '1', :attachment_id => attachment.id, :success => true}, :content_type => content_type
  end

  def upload_attachment
    file = filestream_from_qq_param

    session = MeegoTestSession.find(params[:id])
    session.attachments.create(:file => file)
    @editing = true

    expire_caches_for(session)
    # full file name of template has to be given because flash uploader can pass header HTTP_ACCEPT: text/*
    # file is not found because render :formats=>[:"text/*"]
    html_content = render_to_string :formats => [:html], :partial => 'reports/file_attachment_list', :locals => {:report => session, :files => session.attachments}

    render :json => { :ok => '1', :html_content => html_content, :success => true }, :content_type => content_type
  end

  def merge_result_file
    file = filestream_from_qq_param

    session = MeegoTestSession.find(params[:id])
    @editing = true

    session.merge_result_files!([file])
    if session.errors.empty? && session.save
      session.update_attribute(:editor, current_user)
      expire_caches_for(session)
      html_content = render_to_string :formats => [:html], :partial => 'reports/result_file_list', :locals => {:files => session.result_files}
      render :json => { :ok => '1', :html_content => html_content, :success => true }, :content_type => content_type
    else
      # This is still an IE issue - if JSON response status is not 200 IE will fail handling it
      render :json => { :ok => '0', :errors => session.errors[:result_files], :success => false }, :status => :unprocessable_entity, :content_type => content_type
    end
  end

  def upload
    params[:meego_test_session][:result_files] = FileAttachment.where(:id => params.delete(:drag_n_drop_attachments))

    params[:meego_test_session][:release_version] = params[:release][:name]
    params[:meego_test_session][:target] = params[:profile][:name]

    # Fix tested at date - if it's the current date, add also current time.
    # This needs to be done since reports uploaded via the API have the
    # time as well so reports uploaded manually will always be "older"
    # then the ones from the API if uploading the same day
    unless params[:meego_test_session][:tested_at].blank?
      if DateTime.parse(params[:meego_test_session][:tested_at]).strftime('%Y-%m-%d') == Time.now.strftime('%Y-%m-%d')
        params[:meego_test_session][:tested_at] = Time.now.to_s
      end
    end

    @test_session = ReportFactory.new.build(params[:meego_test_session])
    @test_session.author = current_user
    @test_session.editor = current_user

    set_suggestions

    # Save separately to catch model validation errors
    if @test_session.errors.empty?
      begin
        @test_session.save!
      rescue ActiveRecord::RecordInvalid => e
        # Dynamic form can only show one error message...
        errmsg = if e.record.errors.empty? then "Failed to save report: e.message" else e.record.errors[e.record.errors.keys[0]][1] end
        @test_session.errors.add(:result_files, errmsg)
      end
    end

    if @test_session.errors.empty?
      redirect_to preview_report_path(@test_session)
    else
      @profiles = Profile.names
      render :upload_form
    end
  end

  # IE tries to download JSON responses sent to fileupload.js if
  # content type is something else than text/plain.
  def content_type
    if request.env['HTTP_USER_AGENT'] =~ /msie/i
      'text/plain'
    else
      'application/json'
    end
  end

  private

  def set_suggestions
    scope      = MeegoTestSession.release(@test_session.release.name)
    @testsets  = scope.testsets
    @products  = scope.popular_products
    @build_ids = scope.popular_build_ids
  end

  def filestream_from_qq_param
    if request['qqfile'].respond_to?(:original_filename)
      return request['qqfile']
    # IE uploads come as multipart form data and can be found from this, at least
    elsif request.env['action_dispatch.request.request_parameters']['qqfile']
      return request.env['action_dispatch.request.request_parameters']['qqfile']
    else
      f = StringIO.new(env['rack.input'].read())
      f.original_filename = request['qqfile']
      return f
    end
  end
end
