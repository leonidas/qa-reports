Feature: Check NFT graphs from the web page
  As a user
  I want to see graphical representation of NFT data
  So I can see how things have progressed over time

  Background:
    Given I am a new, authenticated user

    When I follow "Add report"
    And I select target "Handset", test type "NFT" and hardware "N900" with date "2010-11-22"
    And I attach the report "serial_result.xml"
    And submit the form at "upload_report_submit"
    And I press "Publish"

  Scenario: Should see CSV data in view mode
    When I view the report "1.2/Handset/NFT/N900"
    Then I should see "Date,kg"

  Scenario: Should not see CSV data in edit mode
    When I view the report "1.2/Handset/NFT/N900"
    And I follow "Edit"
    Then I should not see "Date,kg"

  @selenium
  Scenario: Open and close NFT trend window
    When I view the report "1.2/Handset/NFT/N900"

    And I click on element "//a[@class='nft_trend_button'][1]"
    Then I should see "simple-case2: temperature" within "#nft_trend_dialog"

    And I click on element "//a[@class='ui_btn modal_close']"

