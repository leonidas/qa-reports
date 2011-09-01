# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110831141133) do

  create_table "features", :force => true do |t|
    t.string  "name",                  :default => ""
    t.integer "meego_test_session_id", :default => 0,  :null => false
    t.string  "comments",              :default => ""
    t.integer "grading"
  end

  add_index "features", ["meego_test_session_id"], :name => "index_meego_test_sets_on_meego_test_session_id"
  add_index "features", ["name"], :name => "index_meego_test_sets_on_feature"

  create_table "file_attachments", :force => true do |t|
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.string   "attachment_type"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
  end

  add_index "file_attachments", ["attachable_id"], :name => "index_file_attachments_on_attachable_id"

  create_table "meego_measurements", :force => true do |t|
    t.integer "meego_test_case_id"
    t.string  "name",                                            :null => false
    t.string  "unit",               :limit => 32,                :null => false
    t.float   "value",                                           :null => false
    t.float   "target"
    t.float   "failure"
    t.integer "sort_index",                       :default => 0, :null => false
  end

  add_index "meego_measurements", ["meego_test_case_id"], :name => "index_meego_measurements_on_meego_test_case_id"

  create_table "meego_test_cases", :force => true do |t|
    t.integer "feature_id",                                               :null => false
    t.string  "name",                                                     :null => false
    t.integer "result",                                                   :null => false
    t.string  "comment",               :limit => 1000, :default => "",    :null => false
    t.integer "meego_test_session_id",                 :default => 0,     :null => false
    t.string  "source_link"
    t.string  "binary_link"
    t.boolean "has_nft",                               :default => false, :null => false
    t.boolean "deleted",                               :default => false, :null => false
  end

  add_index "meego_test_cases", ["deleted", "meego_test_session_id", "result"], :name => "test_case_result_count_index"
  add_index "meego_test_cases", ["feature_id"], :name => "index_meego_test_cases_on_meego_test_set_id"
  add_index "meego_test_cases", ["meego_test_session_id", "name"], :name => "index_meego_test_cases_on_meego_test_session_id_and_name"
  add_index "meego_test_cases", ["meego_test_session_id"], :name => "index_meego_test_cases_on_meego_test_session_id"

  create_table "meego_test_sessions", :force => true do |t|
    t.string   "environment",                       :default => ""
    t.string   "product",                           :default => ""
    t.string   "title",                                                :null => false
    t.string   "target",                            :default => ""
    t.string   "testset",                           :default => ""
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "objective_txt",     :limit => 4000, :default => "",    :null => false
    t.string   "build_txt",         :limit => 4000, :default => "",    :null => false
    t.string   "qa_summary_txt",    :limit => 4000, :default => "",    :null => false
    t.string   "issue_summary_txt", :limit => 4000, :default => "",    :null => false
    t.boolean  "published",                         :default => false
    t.string   "environment_txt",   :limit => 4000, :default => "",    :null => false
    t.datetime "tested_at",                                            :null => false
    t.integer  "author_id",                         :default => 0,     :null => false
    t.integer  "editor_id",                         :default => 0,     :null => false
    t.integer  "release_id",                        :default => 1,     :null => false
    t.string   "build_id",                          :default => ""
  end

  add_index "meego_test_sessions", ["release_id", "target", "testset", "product"], :name => "index_meego_test_sessions_key"

  create_table "releases", :force => true do |t|
    t.string  "label",      :limit => 64, :null => false
    t.string  "normalized", :limit => 64, :null => false
    t.integer "sort_order",               :null => false
  end

  create_table "serial_measurements", :force => true do |t|
    t.integer "meego_test_case_id",                :null => false
    t.string  "name",                              :null => false
    t.integer "sort_index",                        :null => false
    t.string  "short_json",         :limit => 256, :null => false
    t.text    "long_json",                         :null => false
    t.string  "unit",               :limit => 32,  :null => false
    t.float   "min_value",                         :null => false
    t.float   "max_value",                         :null => false
    t.float   "avg_value",                         :null => false
    t.float   "median_value",                      :null => false
    t.string  "interval_unit",      :limit => 32
  end

  add_index "serial_measurements", ["meego_test_case_id"], :name => "index_serial_measurements_on_meego_test_case_id"

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "target_labels", :force => true do |t|
    t.string  "label",      :limit => 64, :null => false
    t.string  "normalized", :limit => 64, :null => false
    t.integer "sort_order",               :null => false
  end

  create_table "test_result_files", :force => true do |t|
    t.integer "meego_test_session_id", :null => false
    t.string  "path"
  end

  add_index "test_result_files", ["meego_test_session_id"], :name => "index_test_result_files_on_meego_test_session_id"

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "password_salt",                       :default => "", :null => false
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "default_target",                      :default => "", :null => false
    t.string   "authentication_token", :limit => 200
  end

  add_index "users", ["authentication_token"], :name => "index_users_on_authentication_token", :unique => true
  add_index "users", ["email"], :name => "index_users_on_email", :unique => true

end
