Feature: REST API
  As an external service
  I want to upload reports via REST API
  So that they can be browsed by users

  Background:
    Given I am an user with a REST authentication token

  Scenario: Uploading a test report with single basic file
    When the client sends a basic test result file
    Then the upload succeeds
    And I should be able to view the created report

  Scenario: Uploading a test report with multiple files and attachments
    When the client sends files with attachments
    Then the upload succeeds
    And I should be able to view the created report

    Then I should see names of the two features
    And I should see the uploaded attachments

  Scenario: Adding a report with tests that do not belong to any feature
    When the client sends a report with tests without features
    Then the upload succeeds
    And I should be able to view the created report

    Then I should see an unnamed feature section
    And I should see the correct amount of test cases without a feature

  Scenario: Adding a report with deprecated parameters
    When the client sends a basic test result file with deprecated parameters
    Then the upload succeeds
    And I should be able to view the created report

  Scenario: Adding a report with deprecated product parameter
    When the client sends a basic test result file with deprecated product parameter
    Then the upload succeeds
    And I should be able to view the created report

  Scenario: Sending a report with string values instead of files
    When the client sends a request with string value instead of a file
    Then the upload fails
    And the result complains about invalid file

  Scenario: Sending a report without a valid report file
    When the client sends a request without file
    Then the upload fails
    And the result complains about missing file

  Scenario: Sending a report without a target profile
    When the client sends a request without a target profile
    Then the upload fails
    And the result complains about missing target profile    

  Scenario: Sending a report with invalid release version
    When the client sends a request with invalid release version
    Then the upload fails
    And the result complains about invalid release version

  Scenario: Sending a report with invalid target profile
    When the client sends a request with invalid target profile
    Then the upload fails
    And the result complains about invalid target profile

  Scenario: Sending a report with product with not allowed characters
    When the client sends a request with invalid product
    Then the upload fails
    And the result complains about invalid product

  # Tests for additional parameters

  Scenario: Sending a report with invalid extra parameters
    When the client sends a request containing invalid extra parameter
    Then the upload fails
    And the result complains about invalid parameter

  Scenario: Sending a report with a user defined report title
    When the client sends a request with a defined title
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined report title

  Scenario: Sending a report with user defined test objective
    When the client sends a request with defined test objective
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined test objective

  Scenario: Sending a report with user defined build information
    When the client sends a request with defined build information
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined build information

  Scenario: Sending a report with user defined build ID
    When the client sends a request with defined build ID
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined build ID

  Scenario: Sending a report with user defined environment information
    When the client sends a request with defined environment information
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined environment information

  Scenario: Sending a report with user defined quality summary
    When the client sends a request with defined quality summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined quality summary

  Scenario: Sending a report with user defined issue summary
    When the client sends a request with defined issue summary
    Then the upload succeeds
    And I should be able to view the created report
    And I should see the defined issue summary

  Scenario: Sending a report with all possible parameters
    When the client sends a request with all optional parameters defined
    Then the upload succeeds
    And I should be able to view the created report

    And I should see the defined report title
    And I should see the defined test objective
    And I should see the defined build ID
    And I should see the defined environment information
    And I should see the defined quality summary
    And I should see the defined issue summary

  # Tests for additional parameters end

  Scenario: Test objective is copied from previous report if not given
    Given the client has sent a request with a defined test objective
    When the client sends a basic test result file

    Then the upload succeeds
    And I should be able to view the latest created report
    And I should see the objective of previous report

  Scenario: Getting a list of sessions from API
    When the client sends three CSV files
    And I download a list of sessions with begin time given
    Then result should match the file with defined date

  Scenario: Getting a list of sessions from API without date
    When the client sends three CSV files
    And I download a list of sessions without a begin time
    Then result should match the file with oldest date
