Feature: As a Test Manager I want to see changes between latest test sessions

  Background:
    Given I am logged in
    And I have created the "1.2/Core/Sanity/FeaturePassRate" report with date "2011-04-18" using "comparison1.csv"
    And I have created the "1.2/Core/Sanity/FeaturePassRate" report with date "2011-04-19" using "comparison2.csv"
    And I have created the "1.2/Core/Sanity/FeaturePassRate" report with date "2011-04-20" using "comparison3.csv"

  @wip
  Scenario: Comparing results between latest and previous test reports
    When I view the group report "1.2/Core/Sanity/FeaturePassRate"
    And I follow "See detailed comparison"

    Then I should see "3" within "#changed_to_pass"
    And I should see "3" within "#changed_from_pass"
    And I should see "1" within "#new_passing"
    And I should see "2" within "#new_failing"
    And I should see "5" within "#new_na"

    And I should see "Description 1" within "#test_case_0 .testcase_name"
    And I should see values "Fail,Pass" in columns of "#test_case_0 td"

    And I should see "Description 4" within "#test_case_3 .testcase_name"
    And I should see values "Pass,N/A" in columns of "#test_case_3 td"
