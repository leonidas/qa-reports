#
# This file is part of meego-qa-reports
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

class NftHistory
  attr_reader :session_measurement_csv_trend

  def initialize()
    @csv_trend = nil
  end
  
  def persisted?
    false
  end

  # Get measurement trends for given session
  #
  # Read all matching measurement values from the beginning of the time until
  # given session (included) and return the data as CSV in a multidimensional 
  # hash that has keys as follows:
  # hash[feature_name][testcase_name][measurement_name] = CSV data
  def session_measurement_csv_trend(session)
    query = <<-END
    SELECT
    meego_test_sets.feature AS feature,
    meego_test_cases.name AS test_case,
    meego_measurements.name AS measurement,
    meego_measurements.unit AS unit,
    meego_measurements.value AS value,
    meego_test_sessions.tested_at AS tested_at
    FROM
    meego_measurements, meego_test_cases, meego_test_sets, meego_test_sessions
    WHERE
    meego_measurements.meego_test_case_id=meego_test_cases.id AND
    meego_test_cases.meego_test_set_id=meego_test_sets.id AND
    meego_test_sets.meego_test_session_id=meego_test_sessions.id AND
    meego_test_sessions.version_label_id=? AND
    meego_test_sessions.target=? AND
    meego_test_sessions.testtype=? AND
    meego_test_sessions.hardware=? AND
    meego_test_sessions.tested_at <= ? AND
    meego_test_sessions.published=?
    ORDER BY
    meego_test_sets.feature ASC, 
    meego_test_cases.name ASC,
    meego_measurements.name ASC,
    meego_test_sessions.tested_at ASC
    END

    data = MeegoTestSession.find_by_sql([query,
                                         session.version_label_id,
                                         session.read_attribute(:target),
                                         session.testtype,
                                         session.hardware,
                                         session.tested_at,
                                         true])


    @csv_trend = Hash.new
    feature = ""
    testcase = ""
    measurement = ""
    csv = ""
    data.each do |m|
      # Start a new measurement
      if feature != m.feature or 
          testcase != m.test_case or 
          measurement != m.measurement 
        
        add_value(feature, testcase, measurement, csv) unless csv.empty?

        unit = "Value"
        if not m.unit.nil?
          unit = m.unit
        end
        csv = "Date,#{unit}\n"
        feature = m.feature
        testcase = m.test_case
        measurement = m.measurement
      end
      
      csv << m.tested_at.strftime("%Y-%m-%d") << "," << m.value.to_s << "\n"
    end

    # Last one was not written in the loop above
    add_value(feature, testcase, measurement, csv) unless csv.empty?

    @csv_trend
  end

  def add_value(feature, testcase, measurement, csv)

    if not @csv_trend.has_key?(feature)
      @csv_trend[feature] = Hash.new
    end

    if not @csv_trend[feature].has_key?(testcase)
      @csv_trend[feature][testcase] = Hash.new
    end

    @csv_trend[feature][testcase][measurement] = csv
  end
end
