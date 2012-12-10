When %r/^report files "([^"]*)" are uploaded to branch "([^"]*)" for product "([^"]*)"$/ do |files, branch, hardware|
  step "I am a user with a REST authentication token"
  step %{the client sends reports "#{files}" via the REST API to test set "#{branch}" and product "#{hardware}"}
end

Then %r/^I should see values "([^"]*)" in columns of "([^"]*)"$/ do |columns, scope|
  columns.split(",").each_with_index{|column, index|
      step %{I should see "#{column}" within "#{scope}.column_#{index}"}
  }
end

Then %r/^I should not see values "([^"]*)" in columns of "([^"]*)"$/ do |columns, scope|
  columns.split(",").each_with_index{|column, index|
      step %{I should not see "#{column}" within "#{scope}.column_#{index}"}
  }
end
 
When /^I get the 1.1\/Core\/Sanity\/Aava page as json$/ do 
  # seems it takes a moment until all reports are available
  sleep 10
  response = get "1.1/Core/Sanity/Aava.json"
  @json_testruns = ActiveSupport::JSON.decode(response.body)
end

When /^I compare the last with the privous test run as json$/ do
  last_id = @json_testruns[0]['id']
  last_id.nil?.should == false
  @response_compare = get "reports/#{last_id}/compare/previous.json"
end

Then /^I ensure it is json and contains the important values$/ do
  json_compare = ActiveSupport::JSON.decode(@response_compare.body)

  comparison = json_compare['comparison']
  comparison.nil?.should == false

  comparison['latest'].nil?.should == false
  comparison['previous'].nil?.should == false

  comparison['changed_to_pass'].nil?.should == false
  comparison['changed_to_pass'].is_a?(Integer).should == true
  comparison['changed_to_pass'].should == 1

  comparison['regression_to_fail'].nil?.should == false
  comparison['regression_to_fail'].is_a?(Integer).should == true
  comparison['regression_to_fail'].should == 2

  comparison['regression_to_na'].nil?.should == false
  comparison['regression_to_na'].is_a?(Integer).should == true

  comparison['changed_to_fail'].nil?.should == false
  comparison['changed_to_fail'].is_a?(Integer).should == true
  comparison['changed_to_fail'].should == 2

  comparison['changed_to_na'].nil?.should == false
  comparison['changed_to_na'].is_a?(Integer).should == true

  comparison['fixed_from_fail'].nil?.should == false
  comparison['fixed_from_fail'].is_a?(Integer).should == true
  comparison['fixed_from_fail'].should == 1

  comparison['fixed_from_na'].nil?.should == false
  comparison['fixed_from_na'].is_a?(Integer).should == true

  comparison['new_passed'].nil?.should == false
  comparison['new_passed'].is_a?(Integer).should == true

  comparison['new_failed'].nil?.should == false
  comparison['new_failed'].is_a?(Integer).should == true
  comparison['new_failed'].should == 1

  comparison['new_na'].nil?.should == false
  comparison['new_na'].is_a?(Integer).should == true
end
