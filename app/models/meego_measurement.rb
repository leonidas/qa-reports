
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

require "nft"

class TargetResultWrapper
  attr_reader :result

  def initialize(res)
    @result = res
  end
end

class MeegoMeasurement < ActiveRecord::Base
  belongs_to :meego_test_case

  include MeasurementUtils

  def result
    return 0 if target.nil? or failure.nil?
    return 1 if target < failure and value < failure
    return 1 if target > failure and value > failure
    return -1
  end

  def is_serial?
    false
  end

  def target_html
    html(target)
  end

  def failure_html
    html(failure)
  end

  def value_html
    html(value)
  end

  def html(val, un=nil)
    un = unit if un.nil?
    "#{format_value(val, 3)}&nbsp;<span class=\"unit\">#{un}</span>".html_safe unless val.nil?
  end

  def relative_html
    return "" if relative.nil?
    html(relative * 100, "%")
  end

  def relative
    return @relative unless @relative.nil? and not target.nil? and not failure.nil?

    @relative = if target < failure
      target/value unless value == 0
    else
      value/target unless target == 0
    end
  end

  # NFT index may be at most 100%, thus limiting the value.
  def nft_index
    return nil if relative.nil?
    [1, relative].min
  end
  
  def target_result
    res = if relative.nil?
      0
    elsif relative < 1
      -1
    else
      1
    end
    TargetResultWrapper.new(res)
  end

end
