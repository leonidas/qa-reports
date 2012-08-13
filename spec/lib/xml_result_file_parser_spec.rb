require 'spec_helper'
require 'xml_result_file_parser'

describe XMLResultFileParser do

  describe "Parsing valid xml file with two features and five test cases" do

    before(:each) do

      @xml_result_file = <<-END
<?xml version="1.0" encoding="UTF-8"?>
  <testresults version="1.0" environment="hardware" hwproduct="RX-71" hwbuild="0720">
    <suite name="simple-suite" timeout="90" manual="false" insignificant="false">
      <set name="simple-set" feature="Feature 1" description="Example test definition" timeout="90" manual="false" insignificant="false" environment="hardware">
       <case name="Test Case 1" timeout="90" manual="false" insignificant="false" result="PASS" comment="comment 1: OK">
        <step manual="false" command="sleep 2" result="PASS">
         <expected_result>0</expected_result>
         <return_code>0</return_code>
         <start>2011-03-04 15:58:43</start>
         <end>2011-03-04 15:58:45</end>
         <stdout></stdout>
         <stderr></stderr>
        </step>
       </case>
       <case name="Test Case 2" timeout="90" manual="false" insignificant="false" result="FAIL" comment="comment 2: FAIL">
        <step manual="false" command="sleep 1" result="FAIL">
         <expected_result>0</expected_result>
         <return_code>0</return_code>
         <start>2011-05-04 15:58:45</start>
         <end>2011-05-04 15:58:46</end>
         <stdout></stdout>
         <stderr></stderr>
        </step>
       </case>
       <case name="Test Case 5" timeout="90" manual="false" insignificant="false" result="FAIL" comment="comment 5: FAIL">
        <step manual="false" command="echo foo" result="NA">
         <expected_result>0</expected_result>
         <return_code>0</return_code>
         <start>2011-03-04 15:58:47</start>
         <end>2011-03-04 15:58:47</end>
         <stdout>foo</stdout>
         <stderr></stderr>
        </step>
       </case>
      </set>
      <set name="simple-set" feature="Feature 2" description="Example test definition" timeout="90" manual="false" insignificant="false" environment="hardware">
       <case name="Test Case 3" timeout="90" manual="false" insignificant="false" result="NA" comment="comment 3: NA">
        <step manual="false" command="sleep 2" result="FAIL">
         <expected_result>0</expected_result>
         <return_code>0</return_code>
         <start>2011-03-04 15:58:43</start>
         <end>2011-03-04 15:58:45</end>
         <stdout></stdout>
         <stderr></stderr>
        </step>
       </case>
       <case name="Test Case 4" timeout="90" manual="false" insignificant="false" result="FAIL" comment="comment 4: FAIL">
        <step manual="false" command="sleep 1" result="FAIL">
         <expected_result>0</expected_result>
         <return_code>0</return_code>
         <start>2011-05-04 15:58:45</start>
         <end>2011-05-04 15:58:46</end>
         <stdout></stdout>
         <stderr></stderr>
        </step>
      </case>
    </set>
  </suite>
</testresults>
END

      # Usage: @test_cases["Feature"]["Testcase"][:field]
      @test_cases = XMLResultFileParser.new.parse(StringIO.new(@xml_result_file))
    end

    it "should have two features" do
      @test_cases.keys.count.should == 2
    end

    it "should have 'Feature 1'" do
      @test_cases.keys.include?("Feature 1").should == true
    end

    it "should have 'Feature 2'" do
      @test_cases.keys.include?("Feature 2").should == true
    end

    it "should have five test cases" do
      test_case_count = @test_cases.values.map { |tcs| tcs.keys.count }.reduce(:+)
      test_case_count.should == 5
    end

    ###############################
    # FEATURE 1
    ###############################
    describe "Feature 1" do
      before(:each) do
        @fea = "Feature 1"
      end

      it "should have three test cases" do
        @test_cases[@fea].keys.count.should == 3
      end

      it "should have test case 'Feature 1, Test Case 1'" do
        @test_cases[@fea].keys.include?("Test Case 1").should == true
      end

      it "should have test case 'Feature 1, Test Case 2'" do
        @test_cases[@fea].keys.include?("Test Case 2").should == true
      end

      it "should have test case 'Feature 1, Test Case 2'" do
        @test_cases[@fea].keys.include?("Test Case 5").should == true
      end

      describe "Test Case 1" do
        before(:each) do
          @tc = "Test Case 1"
        end

        it "should have result PASS" do
          @test_cases[@fea][@tc][:result].should == MeegoTestCase::PASS
        end

        it "should have comment 'comment: OK'" do
          @test_cases[@fea][@tc][:comment].should == "comment 1: OK"
        end
      end

      describe "Test Case 2" do
        before(:each) do
          @tc = "Test Case 2"
        end

        it "should have result FAIL" do
          @test_cases[@fea][@tc][:result].should == MeegoTestCase::FAIL
        end

        it "should have comment 'comment: OK'" do
          @test_cases[@fea][@tc][:comment].should == "comment 2: FAIL"
        end
      end

      describe "Test Case 5" do
        before(:each) do
          @tc = "Test Case 5"
        end

        it "should have result FAIL" do
          @test_cases[@fea][@tc][:result].should == MeegoTestCase::FAIL
        end

        it "should have comment 'comment: OK'" do
          @test_cases[@fea][@tc][:comment].should == "comment 5: FAIL"
        end
      end
    end

    ###############################
    # FEATURE 2
    ###############################
    describe "Feature 2" do
      before(:each) do
        @fea = "Feature 2"
      end

      it "should have two test cases" do
        @test_cases[@fea].keys.count.should == 2
      end

      it "should have test case 'Feature 2, Test Case 3'" do
        @test_cases[@fea].keys.include?("Test Case 3").should == true
      end

      it "should have test case 'Feature 2, Test Case 4'" do
        @test_cases[@fea].keys.include?("Test Case 4").should == true
      end

      describe "Test Case 3" do
        before(:each) do
          @tc = "Test Case 3"
        end

        it "should have result NA" do
          @test_cases[@fea][@tc][:result].should == MeegoTestCase::NA
        end

        it "should have comment 'comment: OK'" do
          @test_cases[@fea][@tc][:comment].should == "comment 3: NA"
        end
      end

      describe "Test Case 4" do
        before(:each) do
          @tc = "Test Case 4"
        end

        it "should have result NA" do
          @test_cases[@fea][@tc][:result].should == MeegoTestCase::FAIL
        end

        it "should have comment 'comment: OK'" do
          @test_cases[@fea][@tc][:comment].should == "comment 4: FAIL"
        end
      end
    end

  end

  describe "Parsing valid xml file with nft results" do

    before(:each) do

      xml_nft_result_file = <<-END
<?xml version="1.0" encoding="UTF-8"?>
<testresults environment="hardware" hwproduct="N900" hwbuild="unknown" version="0.1">
 <suite name="nft-suite" timeout="90" manual="false" insignificant="false">
  <set name="nft-set" feature="nft" description="Example test definition" timeout="90" manual="false" insignificant="false" environment="hardware">
   <case name="case 1" timeout="90" manual="false" insignificant="false" result="PASS">
    <step manual="false" command="sleep 2" result="PASS">
     <expected_result>0</expected_result>
     <return_code>0</return_code>
     <start>2011-03-04 15:58:43</start>
     <end>2011-03-04 15:58:45</end>
     <stdout></stdout>
     <stderr></stderr>
    </step>
    <series name="Current samples" group="Current measurement" unit="mA" interval="100" interval_unit="ms">
     <measurement value="486.800000"/>
     <measurement value="478.400000"/>
    </series>
   </case>
   <case name="case 2" timeout="90" manual="false" insignificant="false" result="PASS">
    <step manual="false" command="sleep 1" result="PASS">
     <expected_result>0</expected_result>
     <return_code>0</return_code>
     <start>2011-05-04 15:58:45</start>
     <end>2011-05-04 15:58:46</end>
     <stdout></stdout>
     <stderr></stderr>
    </step>
    <measurement name="temperature" value="21.000000" unit="C"/>
    <measurement name="bandwidth" value="100.000000" unit="Mb/s"/>
   </case>
   <case name="case 3" timeout="90" manual="false" insignificant="false" result="PASS">
    <step manual="false" command="echo foo" result="PASS">
     <expected_result>0</expected_result>
     <return_code>0</return_code>
     <start>2011-03-04 15:58:47</start>
     <end>2011-03-04 15:58:47</end>
     <stdout>foo</stdout>
     <stderr></stderr>
    </step>
    <measurement name="temperature" value="21.000000" unit="C"/>
    <measurement name="bandwidth" value="100.000000" unit="Mb/s"/>
    <series name="Current samples" group="Current measurement" unit="mA" interval="100" interval_unit="ms">
     <measurement value="545.000000"/>
    </series>
    <series name="temperature" unit="C" target="35.000000" failure="40.000000">
     <measurement timestamp="2011-03-04T13:18:26.000000" value="25.000000"/>
     <measurement timestamp="2011-03-04T13:18:27.005000" value="30.000000"/>
     <measurement timestamp="2011-03-04T13:18:28.000050" value="36.000000"/>
     <measurement timestamp="2011-03-04T13:18:29.250001" value="28.000000"/>
    </series>
   </case>
   <case name="case 4" result="MEASURED">
    <measurement name="pure measured brigthness" value="1000" unit="lm"/>
   </case>
  </set>
 </suite>
</testresults>
END

      # Usage: @test_cases["Feature"]["Testcase"][:field]
      @test_cases2 = XMLResultFileParser.new.parse(StringIO.new(xml_nft_result_file))
    end

    it "should have 'nft' feature" do
      @test_cases2.keys.first.should == 'nft'
    end

    it "should have four test cases" do
     @test_cases2['nft'].keys.should == ["case 1", "case 2", "case 3", "case 4"]
    end

    it "should have correct measurements" do
      @test_cases2['nft']['case 2'][:measurements_attributes][0].should == {
        :name => "temperature", :value => 21.0, :unit => "C", :target => nil, :failure => nil, :sort_index => 0
      }

      @test_cases2['nft']['case 2'][:measurements_attributes][1].should == {
        :name => "bandwidth", :value => 100.0, :unit => "Mb/s", :target => nil, :failure => nil, :sort_index => 0
      }
    end

    it "should have Measured as result for 'case 4'" do
      @test_cases2['nft']['case 4'][:result].should == 2
    end

  end

  describe "Parsing two test sets with same feature" do

    before(:each) do

      xml_nft_result_file = <<-END
<?xml version="1.0" encoding="UTF-8"?>
<testresults environment="hardware" hwproduct="N900" hwbuild="unknown" version="0.1">
 <suite name="nft-suite" timeout="90" manual="false" insignificant="false">
  <set name="Set 1" feature="Feature 1" description="Example test definition" timeout="90" manual="false" insignificant="false" environment="hardware">
   <case name="case 1" timeout="90" manual="false" insignificant="false" result="PASS">
    <step manual="false" command="sleep 2" result="PASS">
     <expected_result>0</expected_result>
     <return_code>0</return_code>
     <start>2011-03-04 15:58:43</start>
     <end>2011-03-04 15:58:45</end>
     <stdout></stdout>
     <stderr></stderr>
    </step>
   </case>
  </set>
 </suite>
 <suite name="nft-suite" timeout="90" manual="false" insignificant="false">
  <set name="Set 2" feature="Feature 1" description="Example test definition" timeout="90" manual="false" insignificant="false" environment="hardware">
   <case name="case 2" timeout="90" manual="false" insignificant="false" result="PASS">
    <step manual="false" command="sleep 2" result="PASS">
     <expected_result>0</expected_result>
     <return_code>0</return_code>
     <start>2011-03-04 15:58:43</start>
     <end>2011-03-04 15:58:45</end>
     <stdout></stdout>
     <stderr></stderr>
    </step>
   </case>
  </set>
 </suite>
</testresults>
END

      # Usage: @test_cases["Feature"]["Testcase"][:field]
      @test_cases2 = XMLResultFileParser.new.parse(StringIO.new(xml_nft_result_file))
    end

    it "should have 'Feature 1' feature" do
      @test_cases2.keys.count.should == 1
      @test_cases2.keys.first.should == 'Feature 1'
    end

    it "should have two test cases" do
     @test_cases2['Feature 1'].keys.count.should == 2
    end
  end

  describe "Parsing two test sets with same feature" do

    before(:each) do

      xml_nft_result_file = <<-END
<?xml version="1.0" encoding="UTF-8"?>
<testresults environment="hardware" hwproduct="N900" hwbuild="unknown" version="0.1">
 <suite name="nft-suite" timeout="90" manual="false" insignificant="false">
  <set name="Set 1" feature="Feature 1" description="Example test definition" timeout="90" manual="false" insignificant="false" environment="hardware">
   <case name="case 1" timeout="90" manual="false" insignificant="false" result="PASS">
    <step manual="false" command="sleep 2" result="PASS">
     <expected_result>0</expected_result>
     <return_code>0</return_code>
     <start>2011-03-04 15:58:43</start>
     <end>2011-03-04 15:58:45</end>
     <stdout></stdout>
     <stderr></stderr>
    </step>
   </case>
  </set>
 </suite>
 <suite name="nft-suite" timeout="90" manual="false" insignificant="false">
  <set name="Set 2" feature="Feature 2" description="Example test definition" timeout="90" manual="false" insignificant="false" environment="hardware">
  </set>
 </suite>
</testresults>
END

      # Usage: @test_cases["Feature"]["Testcase"][:field]
      @test_cases2 = XMLResultFileParser.new.parse(StringIO.new(xml_nft_result_file))
    end

    it "should have 'Feature 1' feature" do
      @test_cases2.keys.count.should == 1
      @test_cases2.keys.first.should == 'Feature 1'
    end

    it "should have two test cases" do
     @test_cases2['Feature 1'].keys.should == ["case 1"]
    end
  end

end
