
def measurement_value(measurement)
  measurement.split.first
end

def measurement_unit(value, target)
  # TODO: use this after we can store null as value:
  # value.split.second || target.split.second
  value.split.second || "dummy"
end

Given %r/^there's an existing report$/ do
  report = FactoryGirl.build(:test_report_wo_features, :tested_at => '2011-09-01')
  report.features << FactoryGirl.build(:feature_wo_test_cases)
  report.features.first.meego_test_cases <<
    FactoryGirl.build(:test_case, :name => 'Test Case 1', :result => MeegoTestCase::PASS, :comment => 'This comment should be used as a template') <<
    FactoryGirl.build(:test_case, :name => 'Test Case 2', :result => MeegoTestCase::PASS, :comment => 'This comment should be overwritten with empty comment')

  report.save!
end

Given %r/^there's a "([^"]*)" report created "([^"]*)" days ago$/ do |categories, count|
  release, profile, testset, product = categories.split '/'
  release, profile, testset, product = nil, release, profile, testset if !product
  report  = FactoryGirl.build(:test_report,
    :release => (release ? Release.find_by_name(release) : Release.first),
    :profile => Profile.find_by_name(profile),
    :testset => testset,
    :product => product,
    :tested_at => count.to_i.days.ago)
  report.save!
end

Given %r/^I view a report with results: (\d+) Passed, (\d+) Failed, (\d+) N\/A$/ do |passed, failed, na|
  report = FactoryGirl.build(:test_report_wo_features)
  report.features << FactoryGirl.build(:feature_wo_test_cases)
  report.features.first.meego_test_cases << FactoryGirl.build_list(:test_case, passed.to_i, :result =>  MeegoTestCase::PASS)
  report.features.first.meego_test_cases << FactoryGirl.build_list(:test_case, failed.to_i, :result =>  MeegoTestCase::FAIL)
  report.features.first.meego_test_cases << FactoryGirl.build_list(:test_case, na.to_i, :result =>  MeegoTestCase::NA)
  report.save!
end

Then %r/^I should see Result Summary:$/ do |table|
  visit report_path MeegoTestSession.first
  with_scope("#test_result_overview") do
    table.hashes.each do |hash|
      actual = find(:xpath, "//tr[td='#{hash[:Title]}']").find(":nth-child(2)").text
      actual.should eql(hash[:Result]), "Expected '#{hash[:Title]}' to be #{hash[:Result]}\nGot #{actual}\n"
    end
  end
end

And %r/^I should not see in Result Summary:$/ do |table|
  #visit report_path MeegoTestSession.first
  with_scope("#test_result_overview") do
    table.hashes.each do |hash|
      page.should have_no_selector(:xpath, "//tr[td='#{hash[:Title]}']"), "Expected no '#{hash[:Title]}'\nBut found one."
    end
  end
end

Given %r/^I view a report with results:$/ do |table|
  report = FactoryGirl.build(:test_report_wo_features)
  report.features << FactoryGirl.build(:feature_wo_test_cases)

  table.hashes.each do |hash|
    result, custom_result = MeegoTestSession.map_result(hash[:Result])
    report.features.first.meego_test_cases << FactoryGirl.build(:test_case,
      :result =>  result,
      :measurements => [FactoryGirl.build(:meego_measurement,
        :value   => measurement_value(hash[:Value]),
        :target  => measurement_value(hash[:Target]),
        :failure => measurement_value(hash[:Fail_limit]),
        :unit    => measurement_unit(hash[:Value], hash[:Target]) )])
  end

  report.save!
end

Given %r/^I create a new test report with same test cases$/ do
  RESULT_CSV = 'Category,Check points,Notes (bugs),Pass,Fail,N A
Bluetooth,Test Case 1,,1,0,0
Bluetooth,Test Case 2,,0,1,0'

  tmp = Tempfile.new('result_file')
  tmp << RESULT_CSV
  file = ActionDispatch::Http::UploadedFile.new(:tempfile => tmp, :filename => 'result.csv')
  report_attributes = MeegoTestSession.first.attributes.merge(:tested_at => '2011-09-02')
  report_attributes[:result_files_attributes] = [{:file => file, :attachment_type => :result_file}]

  report = ReportFactory.new.build(report_attributes)
  report.save!
  report.prev_session.features.count.should == 1
end

Then %r/^I should see the test case comments from the previous test report if the result hasn't changed$/ do
  report = MeegoTestSession.find_by_tested_at('2011-09-02')
  visit report_path(report)
  click_link_or_button('+ see 1 passing tests')
  find_testcase_row("Test Case 1").should have_content("This comment should be used as a template")
  find_testcase_row("Test Case 2").should have_no_content("This comment should be overwritten with empty comment")
end

When %r/^I view the latest report$/ do
  visit report_path(MeegoTestSession.latest)
end

When %r/^I request the report summary as json$/ do
  response = get "/1.2/Core/automated/N900.json"
  json = ActiveSupport::JSON.decode(response.body)

  json.length.should == 1
  json[0]['id'].should_not be_nil

  response = get "/1.2/Core/automated/N900/#{json[0]['id']}/summary.json"
  @json = ActiveSupport::JSON.decode(response.body)
end

Then %r/^I should get the summary for the whole report$/ do
  summary = @json['summary']

  @json['title'].should == 'My Test Report'
  @json['objective'].should == 'To notice regression'
  @json['build'].should == 'foobar-image.bin'
  @json['build_id'].should == '1234.78a'
  @json['environment'].should == 'Laboratory environment'
  @json['qa_summary'].should == 'Ready to ship'
  @json['issue_summary'].should == 'No major issues found'
  @json['prev_session_id'].nil?.should == false


  summary['Total'].should == 25
  summary['Pass'].should == 16
  summary['Fail'].should == 7
  summary['N/A'].should == 2
end

Then %r/^I should get the summary for each feature$/ do
  @json['features'].length.should == 5
  @json['features'].each do |feature|
    summary = feature['summary']

    case feature['name']
    when 'Contacts'
      summary['Total'].should == 1
      summary['Pass'].should == 1
      summary['Fail'].should == 0
      summary['N/A'].should == 0
    when 'Dialer'
      summary['Total'].should == 2
      summary['Pass'].should == 0
      summary['Fail'].should == 0
      summary['N/A'].should == 2
    when 'Audio'
      summary['Total'].should == 2
      summary['Pass'].should == 0
      summary['Fail'].should == 2
      summary['N/A'].should == 0
    when 'Home screen'
      summary['Total'].should == 4
      summary['Pass'].should == 2
      summary['Fail'].should == 2
      summary['N/A'].should == 0
    when 'SIM'
      summary['Total'].should == 16
      summary['Pass'].should == 13
      summary['Fail'].should == 3
      summary['N/A'].should == 0
    end
  end
end

When %r/^I request the report details as JSON$/ do
  response = get "/1.2/Core/automated/N900.json"
  json = ActiveSupport::JSON.decode(response.body)

  json.length.should == 1
  json[0]['id'].should_not be_nil

  response = get "/1.2/Core/automated/N900/#{json[0]['id']}.json"
  @json = ActiveSupport::JSON.decode(response.body)
end

Then %r/^I should get the test cases for each feature$/ do
  @json['features'].each do |feature|
    feature['testcases'].length.should == feature['summary']['Total']

    case feature['name']
    when 'Dialer'
      idx = feature['testcases'].index {|tc| tc['name'] == "Receive a call, accept the call, terminate this call (phonesim, GSM & WCDMA) (GSM and WCDMA cannot be covered until real modem supported,Will use phonesim to test before real modem support)"}
      idx.should_not be_nil

      tc = feature['testcases'][idx]
      tc['result'].should == "N/A"
      tc['comment'].should == "SIM function is not implemented yet."
      tc['bugs'].length.should == 0
      tc['tc_id'].should == nil

    when 'Home screen'
      idx = feature['testcases'].index {|tc| tc['name'] == "Check if core applications* (Dialer, SMS, fennec browser, photo viewer, audio player, video player, contacts, email, Terminal) can be launched from app-launcher"}
      idx.should_not be_nil

      tc = feature['testcases'][idx]
      tc['result'].should == "Fail"
      tc['comment'].should == "<a class=\"bugzilla fetch bugzilla_status bugzilla_append\" href=\"#{BUGZILLA_CONFIG['link_uri']}5856\">5856</a> <a class=\"bugzilla fetch bugzilla_status bugzilla_append\" href=\"#{BUGZILLA_CONFIG['link_uri']}3551\">3551</a> <a class=\"bugzilla fetch bugzilla_status bugzilla_append\" href=\"#{BUGZILLA_CONFIG['link_uri']}3551\">3551</a>"
      tc['bugs'].length.should == 3
      tc['bugs'][0]['id'].should == "5856"
      tc['bugs'][1]['id'].should == "3551"
      tc['bugs'][2]['id'].should == "3551"
      tc['bugs'][0]['url'].should == "#{BUGZILLA_CONFIG['link_uri']}5856"
      tc['bugs'][1]['url'].should == "#{BUGZILLA_CONFIG['link_uri']}3551"
      tc['bugs'][2]['url'].should == "#{BUGZILLA_CONFIG['link_uri']}3551"
      tc['tc_id'].should == nil

    when 'SIM'
      idx = feature['testcases'].index {|tc| tc['name'] == "SMOKE-SIM-Verify_PIN"}
      idx.should_not be_nil

      tc = feature['testcases'][idx]
      tc['result'].should == "Pass"
      tc['comment'].should == ""
      tc['bugs'].length.should == 0
      tc['tc_id'].should == nil
    end
  end
end

When %r/^I request a cumulative report over all reports under "(.*?)" as JSON$/ do |cat|
  # Get the JSON listing of the category (sorted by tested_at date)
  response  = get "/#{cat}.json"
  @cat_json = ActiveSupport::JSON.decode(response.body)

  latest_id = @cat_json.first['id']
  oldest_id = @cat_json.last['id']

  # Get the cumulative report by the IDs
  # TODO: What kind of URI scheme would be nicest for the cumulative report?
  response = get "/#{cat}/cumulative?oldest=#{oldest_id}&latest=#{latest_id}"
  response.status.should == 200
  @json    = ActiveSupport::JSON.decode(response.body)
end

Then %r/^I should get the cumulative summary for the whole report$/ do
  summary = @json['summary']

  # Note: currently case is counted as N/A only if it has not had
  # any other status, i.e. if a case was Passed but has since been
  # N/A it is counted as Passed in the totals
  summary['Total'].should == 18
  summary['Pass'].should  == 7
  summary['Fail'].should  == 6
  summary['N/A'].should   == 5

  seq = @json['sequences']
  seq['titles'].length.should    == 3
  seq['dates'].length.should     == 3
  seq['summaries'].length.should == 3
  seq['features'].length.should  == 4

  (0..2).each do |i|
    seq['titles'][i].should == @cat_json.reverse[i]['title']
    DateTime.parse(seq['dates'][i]).should == DateTime.parse(@cat_json.reverse[i]['tested_at'])
  end

  seq['summaries'][0]['Total'].should    == 6
  seq['summaries'][0]['Pass'].should     == 2
  seq['summaries'][0]['Fail'].should     == 2
  seq['summaries'][0]['N/A'].should      == 2
  seq['summaries'][0]['Measured'].should == 0

  seq['summaries'][1]['Total'].should    == 10
  seq['summaries'][1]['Pass'].should     == 4
  seq['summaries'][1]['Fail'].should     == 6
  seq['summaries'][1]['N/A'].should      == 0
  seq['summaries'][1]['Measured'].should == 0

  seq['summaries'][2]['Total'].should    == 18
  seq['summaries'][2]['Pass'].should     == 7
  seq['summaries'][2]['Fail'].should     == 6
  seq['summaries'][2]['N/A'].should      == 5
  seq['summaries'][2]['Measured'].should == 0

  seq['features'].each do |k,v|
    v.length.should == 3
  end
end

Then %r/^I should get the cumulative summary for each feature$/ do
  @json['features'].length.should == 4
  @json['features'].each do |feature|
    summary = feature['summary']

    case feature['name']
    when 'Feature 1'
      summary['Total'].should == 3
      summary['Pass'].should  == 2
      summary['Fail'].should  == 1
      summary['N/A'].should   == 0
    when 'Feature 2'
      summary['Total'].should == 7
      summary['Pass'].should  == 4
      summary['Fail'].should  == 3
      summary['N/A'].should   == 0
    when 'Feature 3'
      summary['Total'].should == 3
      summary['Pass'].should  == 0
      summary['Fail'].should  == 2
      summary['N/A'].should   == 1
    when 'Feature 4'
      summary['Total'].should == 5
      summary['Pass'].should  == 1
      summary['Fail'].should  == 0
      summary['N/A'].should   == 4
    end
  end
end

Then %r/^I should get the cumulative test cases for each feature$/ do
  @json['features'].each do |feature|
    feature['testcases'].length.should == feature['Total']
  end
end

Then %r/^I see custom result counts in summary$/ do
  summary = @json['summary']

  summary['Total'].should   == 5
  summary['Pass'].should    == 1
  summary['N/A'].should     == 1
  summary['Blocked'].should == 2
  summary['Pending'].should == 1
end

Then /^I should get the test cases with custom results for each feature$/ do
  feature = @json['features'][0]

  feature['testcases'].length.should == 5

  ['NFT-BT-Device_Scan_C-ITER', 'NFT-BT-Device_Scan', 'NFT-BT-Device_Pair', 'NFT-BT-Device_Disconnect', 'NFT-BT-Device_NASTATUS'].each do |tcname|
    idx = feature['testcases'].index {|tc| tc['name'] == tcname}
    idx.should_not be_nil
    tc = feature['testcases'][idx]

    case tcname
    when 'NFT-BT-Device_Scan_C-ITER'
      tc['result'].should == "Pass"
    when 'NFT-BT-Device_Scan'
      tc['result'].should == "Blocked"
    when 'NFT-BT-Device_Pair'
      tc['result'].should == "Blocked"
    when 'NFT-BT-Device_Disconnect'
      tc['result'].should == "Pending"
    when 'NFT-BT-Device_NASTATUS'
      tc['result'].should == "N/A"
    end
  end
end

Then %r/^I should get the cumulative result for each test case$/ do
  # Check that ever test case appears in the final result
  names = Set.new

  @json['features'].each do |feature|
    feature['testcases'].each do |tc|
      names.add tc['name']
    end
  end

  (1..18).each do |n|
    names.should include("Description #{n}")
  end

  # Check for test case comments
  @json['features'].each do |feature|
    feature['testcases'].each do |tc|
      tcname  = tc['name']
      comment = tc['comment']
      result  = tc['result']
      prev_result =tc['prev_result']

      case tcname
      when 'Description 1'
        comment.should == "NA"
      when 'Description 2'
        comment.should == "OK"
        result.should  == "Pass"
        prev_result.should == "Fail"
      when 'Description 3'
        comment.should == "FAIL"
      when 'Description 4'
        comment.should == "OK"
      when 'Description 5'
        comment.should == "OK"
      when 'Description 6'
        comment.should == "Fail"
      when 'Description 7'
        comment.should == "NA"
      when 'Description 8'
        comment.should == "NA"
      when 'Description 9'
        comment.should == "Fail"
      when 'Description 10'
        comment.should == "Fail"
      when 'Description 11'
        comment.should == "NA"
      when 'Description 12'
        comment.should == "Fail"
      when 'Description 13'
        comment.should == "Fail"
      when 'Description 14'
        comment.should == "NA"
      when 'Description 15'
        comment.should == "NA"
      when 'Description 16'
        comment.should == "OK"
      when 'Description 17'
        comment.should == "NA"
      when 'Description 18'
        comment.should == "NA"
      end
    end
  end

end
