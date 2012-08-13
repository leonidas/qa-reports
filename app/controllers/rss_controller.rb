# This file is part of qa-reports
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

class RssController < ApplicationController
  layout false

  def rss
    sort = "created_at"
    if params[:sort] and ['tested_at', 'created_at'].include? params[:sort]
      sort = params[:sort]
    end

    filter = {
        :release_id => release.id,
        :profile_id => Profile.find_by_name(params[:target]).try(:id),
        :testset    => testset,
        :product    => product
      }.delete_if { |key, value| value.nil? }

    @report_shows = MeegoTestSession.published.where(filter).order("#{sort} DESC").limit(10).map{|report| ReportShow.new(report)}

    response.headers["Content-Type"] = "application/xml; charset=utf-8"
  end
end
