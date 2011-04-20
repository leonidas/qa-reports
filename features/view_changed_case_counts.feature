Feature: As a Test Manager I want to see changes between latest test sessions

  Background:
    Given I am a new, authenticated user
    And I have created the "1.2/Core/Sanity/FeaturePassRate" report with date "2011-04-18" using "comparison1.csv"
    And I have created the "1.2/Core/Sanity/FeaturePassRate" report with date "2011-04-19" using "comparison2.csv"
    And I have created the "1.2/Core/Sanity/FeaturePassRate" report with date "2011-04-20" using "comparison3.csv"


  Scenario: View group report
    When I view the group report "1.2/Core/Sanity/FeaturePassRate"
    Then I should see "+3" within "#changed_to_pass"
    And I should see "-5" within "#changed_to_fail"
    And I should see "+6" within "#changed_to_na"
    Then show me the page
    And I should see "4" within "#total_passed"
    And I should see "3" within "#total_failed"
    And I should see "7" within "#total_na"
