# This file is part of qa-reports
#
# Copyright (C) 2012 Jolla Ldt.
#
# Authors: Reto Zingg <reto.zingg@jollamobile.com>
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

require 'xml/smart'
require 'xml/xslt'

class XsltController < ApplicationController
  caches_page :show

  def show
    xmlfile = params[:xml]
    xmlfile = "./public/files/attachments/" + xmlfile

    if File.exists?(xmlfile)
        xslt = XML::XSLT.new()

        xslt.xml = XML::Smart.open(xmlfile)
        xslt.xsl = XML::Smart.open(APP_CONFIG['xml_stylesheet'])

        html = xslt.serve()
        render text:html
    else
        logger.warn "The requested xml file does not exist: %s"%xmlfile
        render :formats => [:html], file:"#{Rails.root}/public/404", :status => 404
    end
  end
end
