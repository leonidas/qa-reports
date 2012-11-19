Meegoqa::Application.routes.draw do
  devise_for :users, :controllers => { :sessions => "users/sessions" }  , :path_names => { :sign_up => "#{DeviseRegistrationConfig::URL_TOKEN}/register" }

  resources :reports, :only => [:index, :show, :update, :destroy] do
    get  'preview', :on => :member
    post 'publish', :on => :member
  end

  resources :features,    :only => [:update]
  resources :test_cases,  :only => [:update]
  resources :attachments, :only => [:destroy]

  match '/upload_post' => 'upload#upload', :via => "post"
  match '/upload_report' => 'upload#upload_report', :via => "post"
  match '/upload_attachment' => 'upload#upload_attachment', :via => "post"
  match '/merge_result_file' => 'upload#merge_result_file', :via => "post"

  match '/api/import' => 'api#import_data', :via => "post"
  match '/api/get_token' => 'api#get_token', :via => "get"
  match '/api/update/:id' => 'api#update_result', :via => "post"
  match '/api/merge/:id' => 'api#merge_result', :via => "post"
  match '/api/reports' => 'api#reports_by_limit_and_time', :via => "get"

  match '/download' => 'csv_export#export_report', :via => "get"

  match '/fetch_bugzilla_data' => 'bugs#fetch_bugzilla_data', :via => "get"

  # to test exception notifier
  match '/raise_exception' => 'exceptions#index' unless Rails.env.production?

  match '/reports/:id/compare/:compare_id' => 'session_comparison#show', :via => "get", :as => :session_comparison

  if !APP_CONFIG['xml_stylesheet'].empty?
    match '/files/attachments/*xml.html' => 'xslt#show', :via => "get"
  end

  # Constraint to allow a dot (.) in release vesion
  constraints(:release_version => /[a-zA-Z0-9._\-\s\%]+/, :id => /[0-9]+/) do
    match '(/:release_version)/index'                                   => 'reports#index',             :via => "get"
    match '(/:release_version)/categories.json'                         => 'reports#categories',        :via => "get"

    match '/:release_version/:target/:testset'                          => 'test_sets#update',          :via => "put"
    match '/:release_version/:target/:testset/:product'                 => 'products#update',           :via => "put"

    match '/:release_version/:target/:testset/:product/:id'             => 'reports#show',             :via => "get", :as => :show_report
    match '/:release_version/:target/:testset/:product/:id/edit'        => 'reports#edit',             :via => "get", :as => :edit_report
    match '/:release_version/:target/:testset/:product/:id/print'       => 'reports#print',            :via => "get", :as => :print_report
    match '/:release_version/:target/:testset/:product/:id/summary.json'=> 'reports#summary',          :via => "get"

    match '/:release_version/:target/:testset/:product/cumulative'      => 'reports#cumulative',       :via => "get"

    match '(/:release_version(/:target(/:testset(/:product))))/upload'  => 'upload#upload_form',       :via => "get", :as => :new_report

    match '(/:release_version(/:target(/:testset(/:product))))/product' => 'products#index',           :via => "get", :as => :products
    match '(/:release_version(/:target(/:testset(/:product))))/testset' => 'test_sets#index',          :via => "get", :as => :test_types
    match '/:release_version/:target(/:testset(/:product))/csv'         => 'csv_export#export',        :via => "get", :as => :group_report_csv
    match '/:release_version/:target/:testset/:product/:id/download'    => 'csv_export#export_report', :via => "get"
    match '/:release_version/:target/:testset/compare/:comparetestset'  => 'comparison_reports#show',  :via => "get", :as => :branch_comparison

    match '/:release_version(/:target(/:testset(/:product)))/rss(/:sort)'       => 'rss#rss',                   :via => "get", :defaults => { :format => 'xml' }

    match '/:release_version/:target(/:testset(/:product))/report_list(/:page)' => 'report_groups#report_page', :via => "get", :as => :report_list
    match '/:release_version/:target(/:testset(/:product))'                     => 'report_groups#show',        :via => "get", :as => :group_report
    match '/:release_version'                                                   => 'reports#index',             :via => "get", :as => :release
  end
    root :to => "reports#index"
end
