Feature: Show latest categories
  This feature is showing last 4 weeks categories which are in active at QA Reports front page as default.

  Background:
    Given I am logged in
    Given I have created the "1.1/Core/Sanity/Aava" report

  @selenium
    Scenario: Viewing the latest categories
      When I am on the front page
      Then I should see "See all categories"
      And I should see "1.1/Core/Sanity/Aava"

    Scenario: Viewing all categories
      When I am on the front page
      And I follow "See all categories"
      Then I should see "See latest categories"
      And I should see "1.1/Core/Sanity/Aava"

