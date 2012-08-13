Feature: RSS Feed

  Background:
    Given I am logged in
    And I have created the "1.1/Core/Sanity/Aava" report using "sim.xml"
    And I have created the "1.1/Core/Sanity/N900" report with date "2008-1-1" using "sim.xml"
    And I have created the "1.1/Core/Weekly/Aava" report using "sim.xml"
    And I have created the "1.1/Handset/Sanity/Aava" report using "sim.xml"
    And I have created the "1.1/Handset/Sanity/N900" report using "sim.xml"
    And I have created the "1.1/Handset/Weekly/Aava" report using "sim.xml"

  Scenario: Fetch RSS feed for leaf level filter
    When I fetch the rss feed for "1.1/Core/Sanity/Aava"
    Then I should see 1 instance of "item"

  Scenario: Fetch RSS feed for test set level filter
    When I fetch the rss feed for "1.1/Core/Sanity"
    Then I should see 2 instances of "item"
    And I should see "Aava"
    And I should see "N900"

  Scenario: Fetch RSS feed for target level filter
    When I fetch the rss feed for "1.1/Core"
    Then I should see 3 instances of "item"
    And I should see "Aava"
    And I should see "N900"
    And I should see "Sanity"
    And I should see "Weekly"

  Scenario: Fetch RSS feed for all reports in specific version
    When I fetch the rss feed for "1.1"
    Then I should see 6 instances of "item"
    And I should see "Core"
    And I should see "Handset"

  Scenario: Fetch RSS feed for test set level filter sorted by tested_at date
    When I fetch the sorted rss feed for "1.1/Core/Sanity"

    Then I should see 2 instances of "item"
    And I should see "Aava"
    And I should see "N900"
    And I should see "2008-01-01" within "item:last"

  Scenario: Verify that offered RSS feeds change according to the page
    When I view the page for the release version "1.1"
    Then I should see the page header offer RSS feed for "1.1"

    When I view the page for the "Handset" profile of release version "1.1"
    Then I should see the page header offer RSS feed for "1.1/Handset"

    When I view the page for "Weekly" testing of profile "Core" in version "1.1"
    Then I should see the page header offer RSS feed for "1.1/Core/Weekly"

    When I view the page for "Sanity" testing of "N900" hardware with profile "Handset" in version "1.1"
    Then I should see the page header offer RSS feed for "1.1/Handset/Sanity/N900"





