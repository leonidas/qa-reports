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

  @default_api_opts_all = @default_api_opts.merge({
    "title"                => "My Test Report",
    "objective_txt"        => "To notice regression",
    "build_txt"            => "foobar-image.bin",
    "build_id_txt"         => "1234.78a",
    "environment_txt"      => "Laboratory environment",
    "qa_summary_txt"       => "Ready to ship",
    "issue_summary_txt"    => "No major issues found"
  })

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
end

After do
  #visit destroy_user_session_path
  #DatabaseCleaner.clean
  Rails.cache.clear
end
