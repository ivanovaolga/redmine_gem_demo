Rails.configuration.to_prepare do
  require 'nrd_reports/hooks'

  require_dependency 'nrd_reports/patches/settings_helper_patch'
  require_dependency 'nrd_reports/patches/user_patch'
  require_dependency 'nrd_reports/patches/issue_patch'
  require_dependency 'nrd_reports/patches/issues_helper_patch'
  require_dependency 'nrd_reports/patches/custom_fields_helper_patch'
  require_dependency 'nrd_reports/initializer'

  require 'nrd_reports/report/resource_provision'
end
