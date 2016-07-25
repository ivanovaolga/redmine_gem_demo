#!/bin/env ruby
# encoding: utf-8

require 'nrd_reports'

Redmine::Plugin.register :nrd_reports do
  name 'Отчетность для планирования'
  author 'datacrafts'
  description 'Отчёт о трудозатратах на устранение рискованных инцидентов 3-й линией поддержки.'
  version '0.0.1'

  settings partial: 'settings/nrd_reports'

  permission :view_resource_reports,                    resource_reports:     :show
  permission :performance_rate_report,                  working_hours:        [:new, :create]
  permission :rework_resources_report,                  rework_resources:     [:new, :create]
  permission :release_calendar_report,                  release_calendars:    [:new, :create]
  permission :resource_provision_report,                resource_provisions:  [:new, :create]
  permission :release_stats_report,                     release_stats:        [:new, :create]
  permission :forecast_perfomance_applications_report,  forecast_perfomances: [:new, :create]

  menu :top_menu, :resource_reports, { controller: :resource_reports, action: :show }, caption: :resource_reports,
       after: :projects, if: Proc.new { User.current.allowed_to?(:view_resource_reports, nil, global: true) }
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable 'system_knowledge'
end
