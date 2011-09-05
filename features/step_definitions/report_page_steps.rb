require 'faster_csv'

def find_feature_row (feature_name)
  feature_name_cell = find(".feature_record a", :text => feature_name) # Locate the feature title cell
  feature_name_cell.find(:xpath, "ancestor::tr[contains(@class, 'feature_record')]") # Locate the parent feature row
end

Then /^I should see the following table:$/ do |expected_report_front_pages_table|
  expected_report_front_pages_table.diff!(tableish('table tr', 'td,th'))
end

Then /^I should see the main navigation columns$/ do
  And %{I should see "Core" within "#report_navigation"}
  And %{I should see "Handset" within "#report_navigation"}
  And %{I should see "Netbook" within "#report_navigation"}
  And %{I should see "IVI" within "#report_navigation"}
end

When /^I should see the sign in link without ability to add report$/ do
  And %{I should see "Sign In"}
  And %{I should not see "Add report"}
end

When /I view the group report "([^"]*)"$/ do |report_string|
  version, target, test_set, product = report_string.downcase.split('/')
  visit("/#{version}/#{target}/#{test_set}/#{product}")
end

Then /^I should see the download link for the result file "([^"]*)"$/ do |result_file|
  with_scope('#raw_file_attachment_list_ready') do
    find_link(result_file)
  end
end

Then /I should see the imported data from "([^"]*)" and "([^"]*)" in the exported CSV.$/ do |file1, file2|
  input = FasterCSV.read('features/resources/' + file1).drop(1) +
          FasterCSV.read('features/resources/' + file2).drop(1)
  result = FasterCSV.parse(page.text, {:col_sep => ';'}).drop(1)
  result.count.should == input.count

  mapped_result = result.map{ |item| [item[6], item[7], item[8], item[9], item[10], item[11]] }
  (input - mapped_result).should be_empty


end

Then /I should see the imported test cases from "([^"]*)" in the exported CSV.$/ do |file|
  input = FasterCSV.read('features/resources/' + file).drop(1)
  result = FasterCSV.parse(page.text, {:col_sep => ','}).drop(1)
  result.count.should == input.count
  mapped_result = result.map{ |item| [item[0], item[1], item[2], item[3], item[4], item[5]] }
  (input - mapped_result).should be_empty
end

When /^(?:|I )(?:|return to )view the report "([^"]*)"$/ do |report_string|
  release, profile, testset, product = report_string.split('/')

  #TODO: Navigate through UI
  visit root_path
  click_link_or_button profile
  visit report_path(MeegoTestSession.last)
end

When /I view the report "([^"]*)" for build$/ do |report_string|
  release, profile, testset, product = report_string.split('/')
  report = MeegoTestSession.first(:conditions =>
   {"releases.name" => release, :target => profile, :product => product, :testset => testset}, :include => :release,
   :order => "build_id DESC, tested_at DESC, created_at DESC")
  raise "report not found with parameters #{release}/#{profile}/#{testset}/#{product}!" unless report
  visit show_report_path(release, profile, testset, product, report)
end

Given /^I have created the "([^"]*)" report(?: using "([^"]*)")?(?: and optional build id is "([^"]*)")?$/ do |report_name, report_template, build_id|
    Given %{I have created the "#{report_name}" report with date "2010-02-02" using "#{report_template}" and optional build id is "#{build_id}"}
  end

Given /^I have created the "([^"]*)" report with date "([^"]*)"(?: using "([^"]*)")?(?: and optional build id is "([^"]*)")?$/ do |report_name, report_date, report_template, build_id|
  version, target, test_set, product = report_name.split('/')

  if not report_template.present?
    report_template = "sample.csv"
  end

  Given "I am on the front page"
  When %{I follow "Add report"}
  And %{I fill in "report_test_execution_date" with "#{report_date}"}
  And %{I choose "#{version}"}
  And %{I select target "#{target}", test set "#{test_set}" and product "#{product}"}
  And %{I select build id "#{build_id}"}
  And %{I attach the report "#{report_template}"}
  And %{I submit the form at "upload_report_submit"}
  And %{I submit the form at "upload_report_submit"}
end

Given /^there exists a report for "([^"]*)"$/ do |report_name|
  version, target, test_set, product = report_name.split('/')

  fpath    = File.join(Rails.root, "features", "resources", "sample.csv")
  testfile = File.new(fpath)

  user = User.create!(:name => "John Longbottom",
    :email => "email@email.com",
    :password => "password",
    :password_confirmation => "password")

  session = MeegoTestSession.new(:target => target, :product => product,
    :testset => test_set, :uploaded_files => [testfile],
    :tested_at => Time.now, :author => user, :editor => user, :release_version => version
  )
  session.generate_defaults! # Is this necessary, or could we just say create! above?
  session.save!
end


When /^I click to edit the report$/ do
  When "I follow \"edit-button\" within \"#edit_report\""
end

When /^I click to print the report$/ do
  When "I follow \"print-button\" within \"#edit_report\""
end

When /^I click to delete the report$/ do
  When "I follow \"delete-button\" within \"#edit_report\""
end

And /there should not be a test case "([^"]*)"$/ do |testcase|
  And %{I should not see "#{testcase}" within ".detailed_results"}
end

When /^(?:|I )should see "([^"]*)" within the test case "([^"]*)"$/ do |text, test_case|
  within(:xpath, "//tr[contains(.,'#{test_case}')]") do
    if page.respond_to? :should
      page.should have_content(text)
    else
      assert page.has_content?(text)
    end
  end
end

When /^(?:|I )submit the comment for the test case "([^"]*)"$/ do |test_case|
  When "I click the element \".small_btn\" for the test case \"#{test_case}\""
end

When /^(?:|I )attach the file "([^"]*)" to test case "([^"]*)"$/ do |file, test_case|
  within(:xpath, "//tr[contains(.,'#{test_case}')]") do
    And "attach the file \"#{Dir.getwd}/features/resources/#{file}\" to \"testcase_attachment\""
  end

  And "I submit the comment for the test case \"#{test_case}\""
end

When /^I remove the attachment from the test case "([^"]*)"$/ do |test_case|
  And "I click the element \"#delete_attachment\" for the test case \"#{test_case}\""
  And "I submit the comment for the test case \"#{test_case}\""
end

When /^I attach the report "([^"]*)"$/ do |file|
  And "attach the file \"#{Dir.getwd}/features/resources/#{file}\" to \"meego_test_session[uploaded_files][]\""
end

Given /^I select target "([^"]*)", test set "([^"]*)" and product "([^"]*)"(?: with date "([^\"]*)")?/ do |target, test_set, product, date|
  When %{I fill in "report_test_execution_date" with "#{date}"} if date
  When %{I choose "#{target}"}
  And %{I select test set "#{test_set}" and product "#{product}"}
end

Given /^I select test set "([^"]*)" and product "([^"]*)"(?: with date "([^\"]*)")?$/ do |test_set, product, date|
  When %{I fill in "report_test_execution_date" with "#{date}"} if date
  When %{I fill in "meego_test_session[testset]" with "#{test_set}"}
  When %{I fill in "meego_test_session[product]" with "#{product}"}
end

Given /^I select build id "([^"]*)"$/ do |build_id|
  When %{I fill in "meego_test_session[build_id]" with "#{build_id}"}
end

Then /^I should see the header$/ do
  Then "I should see \"QA Reports\" within \"#header\""
end

Then /^I should not see the header$/ do
  Then "I should not see \"#header\""
end

When /^I click to confirm the delete$/ do
  find('.dialog-delete').click
end

Then /^(?:|I )should not be able to view the report "([^"]*)"$/ do |report_string|
  version, target, test_set, product = report_string.downcase.split('/')
  report = MeegoTestSession.first(:conditions =>
   {"releases.name" => version, :target => target, :product => product, :testset => test_set}, :include => :release,
   :order => "tested_at DESC, created_at DESC")
  report.should == nil
end

Then /^(?:|I )should see feature "([^"]*)" graded as ([^"]*)$/ do |feature_name, grading_color|
  find_feature_row(feature_name).find(:xpath, "descendant::span")['class'].should =~ /#{grading_color}/ # Check that the color matches the status
end

When /^(?:|I )fill in comment "([^"]*)" for feature "([^"]*)"$/ do |comment, feature_name|
  find_feature_row(feature_name).find(".feature_record_notes").click()
  fill_in("feature[comments]", :with => comment)
end

When /^I (save|cancel) the comment of feature "([^"]*)"$/ do |action, feature_name|
  find_feature_row(feature_name).click_link_or_button(action.capitalize)
end

When /^I change comment of feature "([^"]*)" to "([^"]*)"$/ do |feature_name, comment|
  When %{I fill in comment "#{comment}" for feature "#{feature_name}"}
  And %{I save the comment of feature "#{feature_name}"}
end

When /^I change grading of feature "([^"]*)" to ([^"]*)$/ do |feature_name, grading_color|
  grading_area = find_feature_row(feature_name).find(".feature_record_grading")
  grading_area.click

  grading_area.find("option", :text => grading_color.capitalize).select_option
end
