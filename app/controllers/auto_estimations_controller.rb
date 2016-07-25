class AutoEstimationsController < ApplicationController
  unloadable

  before_filter :require_admin

  def create
    settings = Setting.plugin_nrd_reports

    for_estimation = Issue.joins(:custom_values).where(
      tracker_id: settings[:estimation_tracker],
      custom_values:  {
        value:            [nil, '', '0'],
        custom_field_id:  [settings[:e_dev_field], settings[:e_testing_field]]
      }
    ).uniq

    updated = 0
    for_estimation.each do |issue|
      manual_dev_estimate    = issue.custom_field_value(settings[:e_dev_field]).present?
      manual_tester_estimate = issue.custom_field_value(settings[:e_testing_field]).present?

      updated += 1 if issue.estimate_auto!(manual_dev_estimate, manual_tester_estimate)
    end

    render json: { result: true, response: l(:auto_estimate_done, value: updated) }
  end
end
