# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

if Rails.env == "development" or Rails.env == "staging"
  User.create! :password => 'testpass',
               :email => 'test@leonidasoy.fi',
               :name => "Jean-Claude Van Damme" unless User.exists? :email => 'test@leonidasoy.fi'
end


Release.create! :label => "1.2", :normalized => "1.2", :sort_order => 0
Release.create! :label => "1.1", :normalized => "1.1", :sort_order => 1
Release.create! :label => "1.0", :normalized => "1.0", :sort_order => 2

TargetLabel.create! :label => "Core", :normalized => "core", :sort_order => 0
TargetLabel.create! :label => "Handset", :normalized => "handset", :sort_order => 1
TargetLabel.create! :label => "Netbook", :normalized => "netbook", :sort_order => 2
TargetLabel.create! :label => "IVI", :normalized => "ivi", :sort_order => 3
TargetLabel.create! :label => "SDK", :normalized => "sdk", :sort_order => 4

if Rails.env == "staging" and MeegoTestSession.count < 10000 # ensure there's always 10000 reports on database
  testuser = User.find_by_email("test@leonidasoy.fi")

  fpath = File.join(Rails.root, "features", "resources", "sample.csv")
  tmpfile_path = File.join(Rails.root, "tmp", "tmp_file.csv")
  tmpfile = File.open(tmpfile_path)

  File.open(fpath, "r") do |csv_file|
    File.open(tmpfile_path, "w") do |tmp_file|
      tmp_file.write csv_file.read
    end
  end

  10000.times do
    session = MeegoTestSession.new(
      "build_txt" => "",
      "qa_summary_txt" => "",
      "result_files_attributes" => [{:file => tmpfile, :attachment_type => :result_file}],
      "testset" => "Acceptance",
      "product" => "N900",
      "environment_txt" => "",
      "issue_summary_txt" => "",
      "target" => "Core",
      "objective_txt" => "",
      "release_version" => "1.2"
    )
    session.generate_defaults!
    session.tested_at = Time.now
    session.author = testuser
    session.editor = testuser
    session.published = true
    session.save
  end

end
