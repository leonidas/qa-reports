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
  def show
    xmlfile = params[:xml]
    xmlfile = "./public/files/attachments/" + xmlfile + ".xml"
    if File.exists?(xmlfile)
 
        xslt = XML::XSLT.new()

        xslt.xml = XML::Smart.open(xmlfile)
        print "loaded xml\n"
        xslt.xsl = XML::Smart.open("./lib/xslt/testresults-view.xsl")

        print "loaded xls\n"
        html = xslt.serve()
        render text:html
    else
        render file:"public/404.html", :status => 404
    end
  end
end
