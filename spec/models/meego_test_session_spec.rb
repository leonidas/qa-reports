require 'spec_helper'

describe MeegoTestSession do

  it "should accept valid tested_at date" do
    ['2010-07-15', '2010-11-4', '2011-12-30 23:45:59'].each do |date|
      mts = MeegoTestSession.new(:tested_at => date)
      mts.valid? # called for side effects
      mts.errors[:tested_at].should be_empty
    end
  end

  it "should not accept empty tested_at string" do
      mts = MeegoTestSession.new(:tested_at => '')
      mts.should_not be_valid
  end

  it "should fail to accept invalid tested_at date" do
    mts = MeegoTestSession.new(:tested_at => '2010-13-15')
    mts.should_not be_valid
    mts.errors[:tested_at].should_not be_empty
  end

  it "should create test sets and test cases" do
    params = {
      :title => "Dummy test report",
      :release_version => "1.2",
      :product => "N900",
      :target => "Core",
      :testset => "Sanity",
      :tested_at => "2011-12-30 23:45:59",
      :result_files => [FileAttachment.create]
    }

    mts = MeegoTestSession.new(params)
    mts.valid?
    puts mts.errors
  end

  describe "filters_exist?" do

    before(:each) do
      @session = mock_model(MeegoTestSession)
      MeegoTestSession.stub!(:find_by_target).and_return(@session)
      MeegoTestSession.stub!(:find_by_testset).and_return(@session)
      MeegoTestSession.stub!(:find_by_product).and_return(@session)
      @target = nil
      @testset = nil
      @product = nil
    end

    it "should succeed when all filters exist" do
      @target = 'SomeTarget'
      @testset = 'SomeTestSet'
      @product = 'Someproduct'
      MeegoTestSession.filters_exist?(@target, @testset, @product).should be_true
    end

    it "should succeed when target and testset exist" do
      @target = 'SomeTarget'
      @testset = 'SomeTestSet'
      MeegoTestSession.stub!(:find_by_product).and_return(nil)
      MeegoTestSession.filters_exist?(@target, @testset, @product).should be_true
    end

    it "should succeed when target exists" do
      @target = 'SomeTarget'
      MeegoTestSession.stub!(:find_by_testset).and_return(nil)
      MeegoTestSession.stub!(:find_by_product).and_return(nil)
      MeegoTestSession.filters_exist?(@target, @testset, @product).should be_true
    end


    it "should fail if target is not found" do
      @testset = 'SomeTestSet'
      @product = 'Someproduct'
      MeegoTestSession.stub!(:find_by_target).and_return(nil)
      MeegoTestSession.filters_exist?(@target, @testset, @product).should be_false
    end


    it "should fail if testset is not found and target and product exist" do
      @testset = 'InvalidType'
      @target = 'SomeTarget'
      @product = 'Someproduct'
      MeegoTestSession.stub!(:find_by_testset).and_return(nil)
      MeegoTestSession.filters_exist?(@target, @testset, @product).should be_false
    end
  end
end
