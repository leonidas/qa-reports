@performance
Feature: Loading times
  As a service or real user
  I want every request to complete in a reasonable time

  Background:

    #Note: This measurement assumes that the loading time of the front page
    #      when the database is empty does not change.
    #      Should the front page change a lot, the measurement should be
    #      adjusted.

    Given I measure the speed of the test hardware

  @performance
  Scenario: Upload a big report via web form and view it
    Given I am logged in
    And I am on the front page

    When I start the timer
    And I follow "Add report"
    And I select target "Core", test set "Performance" and product "N990" with date "2010-11-22"
    And I attach the report "2000_cases.csv"
    And submit the form at "upload_report_submit"
    Then the time spent for the "upload report" step should be less than 9 seconds

    When I press "Publish"
    Then the time spent for the "publish report" step should be less than 9 seconds

    And I view the report "1.2/Core/Performance/N990"
    Then the time spent for the "view report" step should be less than 4 seconds

  @performance
  Scenario: Upload bigger reports via API and compare them and load history
    Given I am an user with a REST authentication token

    When I start the timer

    And the client sends file "features/resources/4000_cases.csv" via the REST API
    And the client sends file "features/resources/4000_cases_2.csv" via the REST API
    Then the time spent for the "import 2 reports via API" step should be less than 27 seconds

    When I view the group report "1.2/Core/automated/N900"
    Then the time spent for the "view short group report" step should be less than 2 seconds

    When I follow "See detailed comparison"
    Then the time spent for the "compare two bigger reports" step should be less than 9 seconds

    And the client sends file "features/resources/2000_cases.csv" via the REST API
    And the client sends file "features/resources/2000_cases.csv" via the REST API
    And the client sends file "features/resources/2000_cases.csv" via the REST API
    And the client sends file "features/resources/2000_cases.csv" via the REST API
    Then the time spent for the "import 4 more big reports via API" step should be less than 34 seconds

    When I view the group report "1.2/Core/automated/N900"
    Then the time spent for the "view longer group report" step should be less than 2 seconds

    When I view the report "1.2/Core/automated/N900"
    Then the time spent for the "view big report with full history" step should be less than 25 seconds


