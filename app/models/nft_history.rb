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

require 'fastercsv'

class NftHistory
  attr_reader :measurements, :start_date

  include MeasurementUtils

  GET_START_DATE_QUERY = <<-END
    SELECT
    meego_test_sessions.tested_at AS tested_at
    FROM
    meego_test_sessions, meego_test_cases
    WHERE
    meego_test_cases.meego_test_session_id = meego_test_sessions.id AND
    meego_test_sessions.target             = ? AND 
    meego_test_sessions.testset            = ? AND
    meego_test_sessions.product            = ? AND
    meego_test_sessions.published          = ? AND
    meego_test_sessions.release_id         = ? AND
    (
     EXISTS(SELECT id
            FROM   meego_measurements
            WHERE  meego_test_case_id=meego_test_cases.id)
     OR
     EXISTS(SELECT id
            FROM   serial_measurements
            WHERE  meego_test_case_id=meego_test_cases.id)
    )
    ORDER BY meego_test_sessions.tested_at ASC
    LIMIT 1
    END

  GET_NFT_RESULTS_QUERY = <<-END
    SELECT
    features.name                 AS feature,
    meego_test_cases.name         AS test_case,
    meego_measurements.name       AS measurement,
    meego_measurements.unit       AS unit,
    meego_measurements.value      AS value,
    meego_test_sessions.tested_at AS tested_at
    FROM
    meego_measurements, meego_test_cases, features, meego_test_sessions
    WHERE
    meego_measurements.meego_test_case_id = meego_test_cases.id AND
    meego_test_cases.feature_id           = features.id AND
    features.meego_test_session_id        = meego_test_sessions.id AND
    meego_test_sessions.release_id        = ? AND
    meego_test_sessions.target            = ? AND
    meego_test_sessions.testset           = ? AND
    meego_test_sessions.product           = ? AND
    meego_test_sessions.tested_at        <= ? AND
    meego_test_sessions.published         = ?
    ORDER BY
    features.name ASC,
    meego_test_cases.name ASC,
    meego_measurements.name ASC,
    meego_test_sessions.tested_at ASC
    END

  GET_SERIAL_MEASUREMENTS_QUERY = <<-END
    SELECT
    features.name                    AS feature,
    meego_test_cases.name            AS test_case,
    serial_measurements.name         AS measurement,
    serial_measurements.unit         AS unit,
    serial_measurements.min_value    AS min_value,
    serial_measurements.max_value    AS max_value,
    serial_measurements.avg_value    AS avg_value,
    serial_measurements.median_value AS med_value,
    meego_test_sessions.tested_at    AS tested_at
    FROM
    serial_measurements, meego_test_cases, features, meego_test_sessions
    WHERE
    serial_measurements.meego_test_case_id = meego_test_cases.id AND
    meego_test_cases.feature_id            = features.id AND
    features.meego_test_session_id         = meego_test_sessions.id AND
    meego_test_sessions.release_id         = ? AND
    meego_test_sessions.target             = ? AND
    meego_test_sessions.testset            = ? AND
    meego_test_sessions.product            = ? AND
    meego_test_sessions.tested_at         <= ? AND
    meego_test_sessions.published          = ?
    ORDER BY
    features.name ASC,
    meego_test_cases.name ASC,
    serial_measurements.name ASC,
    meego_test_sessions.tested_at ASC
    END

  def initialize(session)
    @session = session
  end

  def persisted?
    false
  end

  # Get the date of the first session with NFT results
  def start_date
    @first_nft_result_date ||= find_start_date()
  end

  # Get NFT measurements in a multidimensional hash (see find_measurements
  # comment for more information)
  def measurements
    @trend_data ||= find_measurements()
  end

  # Get the serial measurements in a multidimensional hash (see
  # find_serial_measurements comment for more information)
  def serial_measurements
    @serial_trend_data ||= find_serial_measurements()
  end

  protected

  def find_start_date
    data = MeegoTestSession.find_by_sql([GET_START_DATE_QUERY,
                                         @session.read_attribute(:target),
                                         @session.testset,
                                         @session.product,
                                         true,
                                         @session.release_id])

    data[0].tested_at
  end

  # Get measurement trends for given session
  #
  # Read all matching measurement values from the beginning of the time until
  # given session (included) and return the data as CSV in a multidimensional
  # hash that has keys as follows:
  # hash[feature_name][testcase_name][measurement_name]['csv'] = CSV data
  # hash[feature_name][testcase_name][measurement_name]['json'] = array
  #
  # The key figures are on the same level as csv and json data in the hash.
  # The keys for the figures are min, max, avg and med, correspondingly.
  def find_measurements
    data = MeegoTestSession.find_by_sql([GET_NFT_RESULTS_QUERY,
                                         @session.release_id,
                                         @session.read_attribute(:target),
                                         @session.testset,
                                         @session.product,
                                         @session.tested_at,
                                         true])

    handle_db_measurements(data, :nft)
  end

  # Get serial measurement trends for given session. Output format the same
  # as in find_measurements
  def find_serial_measurements
    data = MeegoTestSession.find_by_sql([GET_SERIAL_MEASUREMENTS_QUERY,
                                         @session.release_id,
                                         @session.read_attribute(:target),
                                         @session.testset,
                                         @session.product,
                                         @session.tested_at,
                                         true])

    handle_db_measurements(data, :serial)
  end

  # Go through the results of the DB queries. The serial and NFT versions
  # have only minor differences in handling the results
  def handle_db_measurements(db_data, mode)

    feature     = ""
    testcase    = ""
    measurement = ""
    csv         = nil
    csvstr      = ""
    json        = []

    # This will contain the actual structural measurement data and is
    # what is eventually returned from this method.
    hash = Hash.new

    db_data.each do |db_row|
      # Start a new measurement
      if feature     != db_row.feature or
         testcase    != db_row.test_case or
         measurement != db_row.measurement
        
        # The method creates a FasterCSV and returns it to us
        csv = begin_new_measurement(hash, db_row,
                                    feature, testcase, measurement,
                                    csvstr, json, mode)
      end

      # Store the data to CSV string and JSON array
      if mode == :serial
        csv << [db_row.tested_at.strftime("%Y-%m-%d"),
                db_row.max_value.to_s,
                db_row.avg_value.to_s,
                db_row.med_value.to_s,
                db_row.min_value.to_s]

        # Only medians here, used in the small graph
        json << db_row.med_value

      elsif mode == :nft
        csv << [db_row.tested_at.strftime("%Y-%m-%d"),
                db_row.value.to_s]

        json << db_row.value
      end

    end

    # Last measurement data was not written in the loop above
    add_value(hash, feature, testcase, measurement, "csv", csvstr)
    add_value(hash, feature, testcase, measurement, "json", json)

    count_key_figures(hash)

    hash
  end

  def begin_new_measurement(hash, db_row,
                            feature, testcase, measurement,
                            csvstr, json, mode)

    add_value(hash, feature, testcase, measurement, "csv", csvstr)
    add_value(hash, feature, testcase, measurement, "json", json)

    unit = "Value"
    if not db_row.unit.nil?
      unit = db_row.unit.strip
    end

    # Clear the output buffer
    csvstr.replace("")
    csv = FCSV.new(csvstr, :col_sep => ',')
    if mode == :serial
      csv << ["Date",
              "Max #{unit}",
              "Avg #{unit}",
              "Med #{unit}",
              "Min #{unit}"]
    else
      csv << ["Date", unit]
    end

    json.clear

    feature.replace(db_row.feature)
    testcase.replace(db_row.test_case)
    measurement.replace(db_row.measurement)

    csv
  end

  # Construct the hash that holds all data in previously described structure
  def add_value(container, feature, testcase, measurement, format, data)
    return if data.empty?

    container[feature] ||= Hash.new
    container[feature][testcase] ||= Hash.new
    container[feature][testcase][measurement] ||= Hash.new
    container[feature][testcase][measurement][format] = data.dup
  end

  # Count the key figures that are shown below the small Bluff graphs
  # in history view (min, max, avg, med) and add them to the hash given.
  def count_key_figures(data)
    return if data.nil?

    # If we have measurement data (JSON), get/calculate the key figures
    # (min, max, avg, med) needed for Bluff graphs
    if data.has_key?('json')
      raw_data = data['json']
      
      data['min'] = 'N/A'
      data['max'] = 'N/A'
      data['avg'] = 'N/A'
      data['med'] = 'N/A'

      size = raw_data.size
      if (size > 0)
        # Count the median value
        if (size % 2) == 0
          median = (raw_data[size/2] + raw_data[size/2-1])/2.0
        elsif size > 0
          median = raw_data[size/2]
        end
        
        data['max'] = format_value(raw_data.max, 3)
        data['min'] = format_value(raw_data.min, 3)
        data['med'] = format_value(median, 3)
        data['avg'] = format_value(raw_data.inject{|sum,el| sum + el}.to_f / size, 3)
      end
    else
      # Keep going until the level where the key figures are is found
      data.each do |m, h| count_key_figures(h) end
    end
  end

end
