Feature: REST API update report with nft
  As an external service
  I want to update reports via REST API
  So that they can be browsed by users

  When this API is invoked, the new uploaded result files(XML or CSV) would be parsed and saved in DB, and the original test cases should be removed.
  
  Background:
    Given I am an user with a REST authentication token
    And I have sent a file with NFT results
    And I view the report
    And I see NFT results

  Scenario: Updating test report with NFT cases removed from the report
    When the client sends an updated result file
    Then the upload succeeds
    
    When I view the updated report
    Then I should not see NFT results
