Feature: Check NFT graphs from the web page
  As a user
  I want to see graphical representation of NFT data
  So I can see how things have progressed over time

  Background:
    Given I am logged in
    And I upload two NFT test reports
  
  Scenario: Should see CSV data in view mode
    When I view the report "1.2/Handset/NFT/N900"
    Then I should see "Date,bps"

  Scenario: Should see serial measurement CSV data in view mode
    When I view the report "1.2/Handset/NFT/N900"
    Then I should see "Date,Max bps,Avg bps,Med bps,Min bps"

  Scenario: Should see "See history" link
    When I view the report "1.2/Handset/NFT/N900"
    Then I should see "See history"

  Scenario: Should not see CSV data in edit mode
    When I view the report "1.2/Handset/NFT/N900"
    And I follow "Edit"
    Then I should not see "Date,bps"
 
  Scenario: Should see serial history CSV data
    When I view the report "1.2/Handset/NFT/N900"
    Then I should see "2011-08-09,150.0"
    And I should see "2011-08-09,150.0"

  # Note: the Selenium cases below are based on the JavaScript code updating
  # the title of the hidden modal windows - if we click an item and it works
  # at least to some extent, the title is changed. When these tests pass it
  # does not mean that the graph functionality works since the actual graph
  # may be broken.
  @selenium
  Scenario: Open and close NFT trend window
   When I view the report "1.2/Handset/NFT/N900"

   And I click on the first NFT trend button
   Then I should see "NFT Case 1: Throughput" within "#nft_trend_dialog"

   And I close the trend dialog

  @selenium
  Scenario: Open and close NFT trend window in history view
    When I view the report "1.2/Handset/NFT/N900"
    
    And I follow "See history"

    And I click on the first NFT trend graph
    Then I should see "NFT Case 1: Throughput" within "#nft_trend_dialog"

    And I close the trend dialog

  @selenium
  Scenario: Open and close NFT serial trend window in history view
    When I view the report "1.2/Handset/NFT/N900"
   
    And I follow "See history"

    And I click on the first NFT serial measurement trend graph
    Then I should see "Serial Case: Data rate" within "#nft_series_history_dialog"

    And I close the trend dialog
