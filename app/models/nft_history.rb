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
  attr_reader :measurements, :start_date

  include MeasurementUtils
  
  GET_START_DATE_QUERY = <<-END
    SELECT
    meego_test_sessions.tested_at AS tested_at
    FROM
    meego_test_sessions, meego_test_cases
    WHERE
    meego_test_cases.meego_test_session_id=meego_test_sessions.id AND
    meego_test_sessions.target = ? AND
    meego_test_sessions.testset = ? AND
    meego_test_sessions.product = ? AND
    meego_test_sessions.published = ? AND
    meego_test_sessions.version_label_id = ? AND
    (
     EXISTS(SELECT id 
            FROM meego_measurements 
            WHERE meego_test_case_id=meego_test_cases.id) 
     OR
     EXISTS(SELECT id 
            FROM serial_measurements 
            WHERE meego_test_case_id=meego_test_cases.id)
    )
    ORDER BY meego_test_sessions.tested_at ASC
    LIMIT 1
    END

  GET_NFT_RESULTS_QUERY = <<-END
    SELECT
    features.name AS feature,
    meego_test_cases.name AS test_case,
    meego_measurements.name AS measurement,
    meego_measurements.unit AS unit,
    meego_measurements.value AS value,
    meego_test_sessions.tested_at AS tested_at
    FROM
    meego_measurements, meego_test_cases, features, meego_test_sessions
    WHERE
    meego_measurements.meego_test_case_id=meego_test_cases.id AND
    meego_test_cases.feature_id=features.id AND
    features.meego_test_session_id=meego_test_sessions.id AND
    meego_test_sessions.version_label_id=? AND
    meego_test_sessions.target=? AND
    meego_test_sessions.testset=? AND
    meego_test_sessions.product=? AND
    meego_test_sessions.tested_at <= ? AND
    meego_test_sessions.published=?
    ORDER BY
    features.name ASC, 
    meego_test_cases.name ASC,
    meego_measurements.name ASC,
    meego_test_sessions.tested_at ASC
    END

  GET_SERIAL_MEASUREMENTS_QUERY = <<-END
    SELECT
    features.name AS feature,
    meego_test_cases.name AS test_case,
    serial_measurements.name AS measurement,
    serial_measurements.unit AS unit,
    serial_measurements.min_value AS min_value,
    serial_measurements.max_value AS max_value,
    serial_measurements.avg_value AS avg_value,
    serial_measurements.median_value AS med_value,
    meego_test_sessions.tested_at AS tested_at
    FROM
    serial_measurements, meego_test_cases, features, meego_test_sessions
    WHERE
    serial_measurements.meego_test_case_id=meego_test_cases.id AND
    meego_test_cases.feature_id=features.id AND
    features.meego_test_session_id=meego_test_sessions.id AND
    meego_test_sessions.version_label_id=? AND
    meego_test_sessions.target=? AND
    meego_test_sessions.testset=? AND
    meego_test_sessions.product=? AND
    meego_test_sessions.tested_at <= ? AND
    meego_test_sessions.published=?
    ORDER BY
    features.name ASC, 
    meego_test_cases.name ASC,
    serial_measurements.name ASC,
    meego_test_sessions.tested_at ASC
    END

  def initialize(session)
    @session = session
    @first_nft_result_date = nil

    @trend_data = nil
    @serial_trend_data = nil
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
                                         @session.version_label_id])
    
    @first_nft_result_date = data[0].tested_at
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
                                         @session.version_label_id,
                                         @session.read_attribute(:target),
                                         @session.testset,
                                         @session.product,
                                         @session.tested_at,
                                         true])

    @trend_data = Hash.new
    handle_db_measurements(@trend_data, data, :nft)

    @trend_data

  end

  # Get serial measurement trends for given session. Output format the same
  # as in find_measurements
  def find_serial_measurements
    data = MeegoTestSession.find_by_sql([GET_SERIAL_MEASUREMENTS_QUERY,
                                         @session.version_label_id,
                                         @session.read_attribute(:target),
                                         @session.testset,
                                         @session.product,
                                         @session.tested_at,
                                         true])

    @serial_trend_data = Hash.new
    handle_db_measurements(@serial_trend_data, data, :serial)

    @serial_trend_data
  end

  # Go through the results of the DB queries. The serial and NFT versions
  # have only minor differences in handling the results
  def handle_db_measurements(hash, db_data, mode)

    feature = ""
    testcase = ""
    measurement = ""
    csv = ""
    json = []

    db_data.each do |db_row|
      # Start a new measurement
      if feature != db_row.feature or 
          testcase != db_row.test_case or 
          measurement != db_row.measurement 

        begin_new_measurement(hash, db_row,
                              feature, testcase, measurement,
                              csv, json, mode)
      end

      # Store the data to CSV string and JSON array
      if mode == :serial
        csv << 
          db_row.tested_at.strftime("%Y-%m-%d") << "," << 
          db_row.max_value.to_s << "," << 
          db_row.avg_value.to_s << "," << 
          db_row.med_value.to_s << "," << 
          db_row.min_value.to_s << "\n"

        # Only medians here, used in the small graph
        json << db_row.med_value

      elsif mode == :nft
        csv << 
          db_row.tested_at.strftime("%Y-%m-%d") << "," << 
          db_row.value.to_s << "\n"

        json << db_row.value        
      end

    end

    # Last measurement data was not written in the loop above
    add_value(hash, feature, testcase, 
              measurement, "csv", csv) unless csv.empty?
    add_value(hash, feature, testcase, 
              measurement, "json", json) unless json.empty?

    count_key_figures(hash)

    hash
  end

  def begin_new_measurement(hash, db_row, 
                            feature, testcase, measurement,
                            csv, json, mode)

    add_value(hash, feature, testcase, measurement, 
              "csv", csv) unless csv.empty?
    add_value(hash, feature, testcase, measurement, 
              "json", json) unless json.empty?
    
    unit = "Value"
    if not db_row.unit.nil?
      unit = db_row.unit
    end
        
    csv.replace("")
    if mode == :serial
      csv << "Date,Max #{unit},Avg #{unit},Med #{unit},Min #{unit}\n"
    else
      csv << "Date,#{unit}\n"
    end

    json.clear
    
    feature.replace(db_row.feature)
    testcase.replace(db_row.test_case)
    measurement.replace(db_row.measurement)
  end

  # Construct the hash that holds all data in previously described structure
  def add_value(container, feature, testcase, measurement, format, data)
    
    if not container.has_key?(feature)
      container[feature] = Hash.new
    end

    if not container[feature].has_key?(testcase)
      container[feature][testcase] = Hash.new
    end

    if not container[feature][testcase].has_key?(measurement)
      container[feature][testcase][measurement] = Hash.new
    end
    
    # Hashes for this particular measurement exist and data can be stored
    container[feature][testcase][measurement][format] = data.dup
  end

  # Count the key figures that are shown below the small Bluff graphs
  # in history view (min, max, avg, med) and add them to the hash given.
  def count_key_figures(container)
    container.each do |feature, testcases|
      count_testcase_key_figures(testcases)
    end
  end

  def count_testcase_key_figures(testcases)
    testcases.each do |testcase, measurements|
      count_measurement_key_figures(measurements)
    end
  end
  
  def count_measurement_key_figures(measurements)
    measurements.each do |measurement, data|
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
      end
    end
  end

end
