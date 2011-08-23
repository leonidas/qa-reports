Feature: Manage api_update_cases
  In order to provide a REST API for updating the result of test cases from a special report. 
  The API respond at /api/update/<report_id>
  When this API is invoked, the new uploaded result files(XML or CSV) would be parsed and saved in DB, and the original test cases should be removed. 
  
  Background:
    Given I am an user with a REST authentication token
    And I have sent a basic result file

  Scenario: Updating test report with valid result file
    When the client sends an updated result file

    Then the upload succeeds
    When I view the report
    Then I should see "updated_case"

  Scenario: Updating test report with an invalid result file
    When the client sends an updated but invalid result file
    Then the upload fails
    When I view the report
    Then I should not see "updated_case"
    And I should see "SMOKE-SIM-Query_SIM_card_status"

  Scenario: Updating test report with a file with invalid extension
    When the client sends an updated file with invalid extension

    Then the upload fails
    When I view the report
    Then I should not see "updated_case"
    And I should see "SMOKE-SIM-Query_SIM_card_status"

  Scenario: Updating test report with multiple valid result files
    When the client sends several updated files

    Then the upload succeeds
    When I view the report
    Then I should see "updated_case"

  Scenario: Updating test report with a valid and an invalid file
    When the client sends a valid and an invalid file

    Then the upload fails

    When I view the report
    Then I should not see "updated_case"
    And I should see "SMOKE-SIM-Query_SIM_card_status"
