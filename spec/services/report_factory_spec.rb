require 'pp'
require 'spec_helper'
require 'report_factory'

describe ReportFactory do

  describe "a report build with valid attributes" do
    before(:each) do

      @result_file1 = Object.new
      @result_file2 = Object.new

      @result_file1.stub(:original_filename).and_return("bluetooth.xml")
      @result_file2.stub(:original_filename).and_return("wlan.csv")

      @result_file1.stub(:path).and_return("/var/tmp/bluetooth.xml")
      @result_file2.stub(:path).and_return("/var/tmp/wlan.csv")

      @result_file1.stub(:close).and_return(true)
      @result_file2.stub(:close).and_return(true)

      @result_file1.stub(:pos=)
      @result_file2.stub(:pos=)

      @result_attachment1 = FileAttachment.new
      @result_attachment2 = FileAttachment.new

      @result_attachment1.stub_chain(:file, :to_file).and_return(@result_file1)
      @result_attachment2.stub_chain(:file, :to_file).and_return(@result_file2)

      @result_attachment1.stub(:filename).and_return(@result_file1.original_filename)
      @result_attachment2.stub(:filename).and_return(@result_file2.original_filename)

      @report_attributes = {
        :release_version => "1.1",
        :target => "Core",
        :testset => "Sanity",
        :product => "N900",
        :tested_at => "2011-12-30 23:45:59",
        :result_files => [@result_attachment1, @result_attachment2]
      }

      @test_cases1 = {
        "Test Case 1" => {:name => "Test Case 1", :result => 1, :comment => "OK"   },
        "Test Case 2" => {:name => "Test Case 2", :result => -1, :comment => "FAIL"},
        "Test Case 3" => {:name => "Test Case 3", :result => 0, :comment => "NA"   }
      }

      @test_cases2 = {
        "Test Case 1" => {:name => "Test Case 1", :result => -1, :comment => "FAIL"  },
        "Test Case 4" => {:name => "Test Case 4", :result => -1, :comment => "FAIL"},
        "Test Case 5" => {:name => "Test Case 5", :result => 0, :comment => "NA"   }
      }

      @results1 = { "Feature 1" =>  @test_cases1, "Feature 2" => @test_cases1 }
      @results2 = { "Feature 1" => @test_cases2, "Feature 3" => @test_cases2 }


      @xml_parser = Object.new
      @csv_parser = Object.new

      XMLResultFileParser.stub(:new).and_return(@xml_parser)
      CSVResultFileParser.stub(:new).and_return(@csv_parser)

      @xml_parser.stub(:parse).and_return(@results1)
      @csv_parser.stub(:parse).and_return(@results2)

      @xml_parser.stub(:parse_metrics).and_return(nil)

      FileUtils.stub(:move)
      @report = ReportFactory.new.build(@report_attributes)
      @report.author = stub_model(User)
      @report.editor = stub_model(User)
    end

    it "should be a valid report" do
      @report.should be_valid
    end

    describe "the report" do
      before(:each) do
        @report.save!
      end

      it "should have title 'Core Test Report: N900 Sanity 2011-12-30" do
        @report.title.should == "Core Test Report: N900 Sanity 2011-12-30"
      end

      it "should have release '1.1" do
        @report.release.name == "1.1"
      end

      it "should have environment '* Hardware: N900'" do
        @report.environment_txt == "* Hardware: N900"
      end

      it "should have three features" do
        @report.features.count.should == 3
      end

      it "should have features 'Feature 1', 'Feature 2', 'Feature 3'" do
        ["Feature 1", "Feature 2", "Feature 3"].each do |feature_name|
          @report.features.map {|feature| feature.name }.include?(feature_name).should == true
        end
      end

      it "should have five, three and three test cases within Features 1, 2 and 3" do
        {"Feature 1" => 5, "Feature 2" => 3, "Feature 3" => 3}.each do |feature, tc_count|
          @report.features.by_feature(feature).meego_test_cases.count.should == tc_count
        end
      end

      it "should have test cases 1-5 within Feature 1" do
        test_cases = @report.features.by_feature("Feature 1").meego_test_cases

        ["Test Case 1","Test Case 2", "Test Case 3", "Test Case 4", "Test Case 5"].each do |tc_name|
          test_cases.map{|tc| tc.name }.include?(tc_name).should == true
        end
      end

      it "should have test cases 1-3 within Feature 2" do
        test_cases = @report.features.by_feature("Feature 2").meego_test_cases

        ["Test Case 1","Test Case 2", "Test Case 3"].each do |tc_name|
          test_cases.map{|tc| tc.name }.include?(tc_name).should == true
        end
      end

      it "should have test cases 1,4 and 5 within Feature 3" do
        test_cases = @report.features.by_feature("Feature 3").meego_test_cases

        ["Test Case 1","Test Case 4", "Test Case 5"].each do |tc_name|
          test_cases.map{|tc| tc.name }.include?(tc_name).should == true
        end
      end

      describe "merged test set 'Feature 1'" do
        it "should contain the result from the latest result file" do
          test_case = @report.features.by_feature("Feature 1").
            meego_test_cases.by_name("Test Case 1")

          test_case.result.should == MeegoTestCase::FAIL
          test_case.comment.should == "FAIL"
        end
      end

    end
  end

  it "should produce a valid report from input file containing TC_IDs" do

    author = User.new({:email => 'foo@bar.com', :password => 'minsixchars', :name => 'Test User'})
    author.save!

    file = File.new("spec/fixtures/sim1.xml")
    data = {}

    data[:release_version] = "1.2"
    data[:target]          = "Core"
    data[:testset]         = "TC_ID"
    data[:product]         = "N900"
    data[:result_files]    = [FileAttachment.new(:file => file, :attachment_type => :result_file)]

    test_session        = ReportFactory.new.build(data)
    test_session.author = author
    test_session.editor = author
    test_session.save!

    MeegoTestCase.find(:first, :conditions => "tc_id = 'smoke-123'").should_not be_nil

  end

  it "should produce a valid report from input file with custom results" do
    APP_CONFIG['custom_results'] = ['Blocked', 'Pending', 'Upstream']
    CustomResult.create([{:name => "Blocked"},{:name => "Pending"},{:name => "Upstream"}])

    author = User.new({:email => 'foo@bar.com', :password => 'minsixchars', :name => 'Test User'})
    author.save!

    file = File.new("features/resources/custom_statuses.xml")
    file.stub(:original_filename).and_return("custom_statuses.xml")
    data = {}

    data[:release_version] = "1.2"
    data[:target]          = "Core"
    data[:testset]         = "CustomStatus"
    data[:product]         = "N900"
    data[:result_files]    = [FileAttachment.new(:file => file, :attachment_type => :result_file)]

    test_session        = ReportFactory.new.build(data)
    test_session.author = author
    test_session.editor = author
    # Need to save, otherwise associations do not exist
    test_session.save!

    test_session.meego_test_cases.each do |tc|
      case tc.name
      when "NFT-BT-Device_Scan_C-ITER"
        tc.result.should == MeegoTestCase::PASS
      when "NFT-BT-Device_Scan"
        tc.result.should             == MeegoTestCase::CUSTOM
        tc.custom_result.name.should == "Blocked"
      when "NFT-BT-Device_Pair"
        tc.result.should == MeegoTestCase::CUSTOM
        tc.custom_result.name.should == "Blocked"
      when "NFT-BT-Device_Disconnect"
        tc.result.should == MeegoTestCase::CUSTOM
        tc.custom_result.name.should == "Pending"
      end
    end
  end

  it "should validate custom results against configured ones" do
    APP_CONFIG['custom_results'] = ['Blocked']
    CustomResult.create([{:name => "Blocked"}, {:name => "Pending"}])

    author = User.new({:email => 'foo@bar.com', :password => 'minsixchars', :name => 'Test User'})
    author.save!

    file = File.new("features/resources/custom_statuses.xml")
    file.stub(:original_filename).and_return("custom_statuses.xml")
    data = {}

    data[:release_version] = "1.2"
    data[:target]          = "Core"
    data[:testset]         = "CustomStatus"
    data[:product]         = "N900"
    data[:result_files]    = [FileAttachment.new(:file => file, :attachment_type => :result_file)]

    test_session        = ReportFactory.new.build(data)
    test_session.author = author
    test_session.editor = author
    # Need to save, otherwise associations do not exist
    test_session.save.should be_false
  end
end
