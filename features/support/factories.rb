FactoryGirl.define do
  sequence :email do |n| 
    "john.longbottom#{n}@meego.com"
  end

  sequence :authentication_token do |n| 
    n.to_s
  end

  factory :user, :aliases => [:author, :editor] do
    name                  "John Longbottom"
    email
    password              "secret"
    password_confirmation "secret"
    authentication_token
  end

  factory :release, :class => VersionLabel, :aliases => [:version_label] do
    label      "1.3"
    normalized "1.3"
    sort_order  0
  end

  factory :feature do
    name "Bluetooth"
  end

  factory :test_case, :class => MeegoTestCase do
    name   "Bluetooth file transfer"
    result MeegoTestCase::PASS
  end

  factory :test_report, :class => MeegoTestSession do
    after_build { |report| FactoryGirl.build(:feature, :meego_test_session => report)}
    author
    editor
    version_label
    title           "N900 Test Report"
    target          "Handset"
    testset         "Acceptance"
    product         "N900"
    published       true
    tested_at       "2011-08-06"
    uploaded_files  "result.csv"
  end

  # NFT stuff

  factory :meego_measurement do
    name        "Throughput"
    unit        "bps"
    value       150
    target      135
    failure     115
  end
  
  factory :serial_measurement do
    name          "Data rate"
    short_json    "1.7e+03,3.2e+03,3.2e+03"
    long_json     "[[0,1730.364014],[695,3238.187012],[1462,3238.187012]]"
    unit          "bps"
    min_value     1730.36
    max_value     3238.19
    avg_value     2735.58
    median_value  3238.19
    interval_unit "h"
    sort_index    1
  end

  factory :nft_test_case, :class => MeegoTestCase do
    after_create { |testcase|
      FactoryGirl.create(:meego_measurement,
                         :meego_test_case => testcase)
      FactoryGirl.create(:meego_measurement,
                         :meego_test_case => testcase,
                         :name            => "Latency",
                         :unit            => "ms",
                         :value           => 90)
    }
    name   "NFT case"
    result MeegoTestCase::PASS
  end

  factory :nft_serial_test_case, :class => MeegoTestCase do
    after_create{ |testcase|
      FactoryGirl.create(:serial_measurement,
                         :meego_test_case => testcase)
    }
    name   "NFT Serial case"
    result MeegoTestCase::PASS
  end

  factory :nft_feature, :class => Feature do
    after_create { |feature|
      FactoryGirl.create(:nft_test_case, 
                         :feature => feature, 
                         :meego_test_session => feature.meego_test_session,
                         :name => "NFT Case 1")
      FactoryGirl.create(:nft_test_case, 
                         :feature => feature, 
                         :meego_test_session => feature.meego_test_session,
                         :name => "NFT Case 2")
      FactoryGirl.create(:nft_serial_test_case, 
                         :feature => feature, 
                         :meego_test_session => feature.meego_test_session,
                         :name => "Serial Case")

    }
    name "NFT Tests"
  end

  factory :nft_test_report, :class => MeegoTestSession do
    after_create { |report| 
      FactoryGirl.create(:nft_feature, :meego_test_session => report)
    }
    author
    editor
    version_label   {VersionLabel.where(:normalized => '1.2').first}
    title           "N900 NFT TEST REPORT"
    target          "Handset"
    testset         "NFT"
    product         "N900"
    published       true
    tested_at       "2011-08-06"
    uploaded_files  "result.csv"
  end
end
