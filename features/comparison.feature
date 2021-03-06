Feature: Consolidated reports
  As a Release Manager
  I want to compare reports of different hardware versions between branches
  So that I can decide if it's safe to create new release

  @wip @javascript
  Scenario: Comparing results between two branches with differences
    When report files "spec/fixtures/sim1.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity" for product "N900"
    And report files "spec/fixtures/sim1.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity" for product "N910"
    And report files "spec/fixtures/sim1.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity:Testing" for product "N900"
    And report files "spec/fixtures/sim2.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity:Testing" for product "N910"

    When I am on the front page
    And I follow "compare"

    Then I should see "1" within "#changed_to_pass"
    And I should see "2" within "#changed_from_pass"
    And I should see "1" within ".changed_from_fail"
    And I should see "0" within ".changed_from_na"
    And I should see "2" within ".fail.changed_from_pass"
    And I should see "0" within ".na.changed_from_pass"


    And I should see "0" within "#new_passing"
    And I should see "1" within "#new_failing"
    And I should see "0" within "#new_na"

    And I should see values "N900,N910,N900,N910" in columns of "tr.compare_testset th"

    And I should see "SMOKE-SIM-Disable_PIN_query" within "#test_case_13 .testcase_name"
    And I should see values "Fail,Fail,Fail,Pass" in columns of "#test_case_13 td"

    And I should see "SMOKE-SIM-Get_IMSI" within "#test_case_4 .testcase_name"
    And I should see values "Pass,Pass,Pass,Fail" in columns of "#test_case_4 td"

  @javascript
  Scenario: Comparing results as json
    When I am logged in
    And I have created the "1.1/Core/Sanity/Aava" report with date "2012-12-06" using "../../spec/fixtures/sim1.xml"
    And I have created the "1.1/Core/Sanity/Aava" report with date "2012-12-07" using "../../spec/fixtures/sim2.xml"

    When I get the 1.1/Core/Sanity/Aava page as json
    And I compare the last with the privous test run as json

    Then I ensure it is json and contains the important values

  @javascript
  Scenario: Comparing results between two branches where data is missing for one device
    When report files "spec/fixtures/sim1.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity" for product "N900"
    And report files "spec/fixtures/sim1.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity" for product "N910"
    And report files "spec/fixtures/sim2.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity:Testing" for product "N910"

    When I am on the front page
    And I follow the first "compare"

    Then I should see "1" within "#changed_to_pass"
    And I should see "2" within "#changed_from_pass"
    And I should not see values "N900" in columns of "tr.compare_testset th"

  @javascript
  Scenario: Toggle visibility of unchanged results
    When report files "spec/fixtures/sim1.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity" for product "N910"
    And report files "spec/fixtures/sim2.xml,features/resources/bluetooth.xml" are uploaded to branch "Sanity:Testing" for product "N910"

    When I am on the front page
    And I follow the first "compare"

    Then I should really see "SMOKE-SIM-Query_SIM_card_status"
    And I really should not see "SMOKE-SIM-Write_read_and_delete_ADN_phonebook_entry"
    And I should see active "Changed"
    And I should see inactive "See all"

    Then I press "See all"

    Then I should really see "SMOKE-SIM-Query_SIM_card_status"
    And I should really see "SMOKE-SIM-Write_read_and_delete_ADN_phonebook_entry"
    And I should see inactive "Changed"
    And I should see active "See all"



