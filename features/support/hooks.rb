Before do
  @default_api_opts = {
    "auth_token"      => "foobar",
    "release_version" => "1.2",
    "target"          => "Core",
    "testset"         => "automated",
    "product"         => "N900",
    "tested_at"       => "2010-1-1",
    "report.1"        => Rack::Test::UploadedFile.new("features/resources/sim.xml", "text/xml")
  }

  # The oldest API (hwproduct and testtype have since been renamed)
  @default_version_1_api_opts = @default_api_opts.merge({
    "hwproduct"       => "N900",
    "testtype"        => "automated"
  })
  @default_version_1_api_opts.delete("testset")
  @default_version_1_api_opts.delete("product")

  # The 2nd API (hardware has since been renamed)
  @default_version_2_api_opts = @default_api_opts.merge({
    "hardware"        => "N900"
  })
  @default_version_2_api_opts.delete("product")

  @testcase_template = {
  :name => "dummy testcase", :result => 1, :comment => "dummy"
  }
  @feature_template = {
    :name => "dummy feature", :meego_test_cases_attributes => [@testcase_template]
  }
  @report_template = {
    :release_version => "1.2",
    :target => "Core",
    :testset => "Sanity",
    :product => "N900",
    :tested_at => "2011-12-30 23:45:59",
    :published => true,
    :title => "dummy title",
    :uploaded_files => "dummy_file.csv",
    :features_attributes => [@feature_template]
  }
end

After do
  #visit destroy_user_session_path
  #DatabaseCleaner.clean
end
