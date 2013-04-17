APP_CONFIG = YAML.load_file("#{::Rails.root.to_s}/config/config.yml")

APP_CONFIG['allow_empty_files']      ||= false
APP_CONFIG['hide_empty_targets']     ||= false
APP_CONFIG['inline_images']          ||= false
APP_CONFIG['show_registration_link'] ||= false

APP_CONFIG['custom_results']     ||= []
APP_CONFIG['app_name']           ||= "MeeGo QA Reports"
APP_CONFIG['custom_css']         ||= ''
APP_CONFIG['feedback_link']      ||= 'mailto:meego-qa@lists.meego.com'
APP_CONFIG['documantation_link'] ||= 'https://github.com/leonidas/qa-reports/wiki'
APP_CONFIG['idea_link']          ||= 'https://github.com/leonidas/qa-reports/issues'
APP_CONFIG['date_format']        ||= '%d %B %Y'
APP_CONFIG['table_date_format']  ||= '%d.%m'
APP_CONFIG['xml_stylesheet']     ||= ''
APP_CONFIG['api_mapping']        ||= {'release_version' => '', 'target' => '', 'testset' => '', 'product' => ''}
APP_CONFIG['group_labels']       ||= {'release_version' => 'MeeGo release',
                                      'target' => 'Target profile',
                                      'testset' => 'Test set',
                                      'product' => 'Product'}

APP_CONFIG['patches_included_default_prefix'] ||= ''
APP_CONFIG['issue_summary_default_prefix']    ||= ''

# Check the group labels and set to defaults if not defined
if APP_CONFIG['group_labels']['release_version'].blank?
  APP_CONFIG['group_labels']['release_version'] = 'MeeGo release'
end
if APP_CONFIG['group_labels']['target'].blank?
  APP_CONFIG['group_labels']['target'] = 'Target profile'
end
if APP_CONFIG['group_labels']['testset'].blank?
  APP_CONFIG['group_labels']['testset'] = 'Test set'
end
if APP_CONFIG['group_labels']['product'].blank?
  APP_CONFIG['group_labels']['product'] = 'Product'
end

# Check that the xsl file exists
if !APP_CONFIG['xml_stylesheet'].empty? && !File.exists?(APP_CONFIG['xml_stylesheet'])
  puts "WARNING: #{APP_CONFIG['xml_stylesheet']} does not exist. Disabling XSLT" # Rails.logger not available yet
  APP_CONFIG['xml_stylesheet'] = ''
end

if CustomResult.table_exists?
  APP_CONFIG['custom_results'].each do |cr|
      CustomResult.find_or_create_by_name cr
  end
end
