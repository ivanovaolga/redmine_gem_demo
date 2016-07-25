module WorkingHoursHelper
  def report_date_field(name)
    content_tag(:div, class: 'report-date-filter') do
      concat calendar_for(name)
      concat label_tag(name, l(name) + ': ')
      concat text_field_tag(name, nil)
    end
  end

  def user_info(user, field_id)
    resource_issues = Issue
      .joins(:custom_values)
      .where(
        custom_values: {
          custom_field_id: settings[:resource_assigned_field],
          value:           user.id
        },
        tracker_id: settings[:resource_tracker]
      )

    if resource_issues.count == 1
      dept = resource_issues.first.custom_field_value(field_id)
    end
  end

  def work_efforts(issue)
    spent_on_range = params[:report_start_date]..params[:report_end_date]
    issue.time_entries.where(spent_on: spent_on_range).includes(:user).select('user_id, SUM(hours) as hours').group('user_id')
  end

  def inactive_users(issue, time_entries)
    assigned_ids = issue.journals.joins(:details).where(journal_details: { prop_key: :assigned_to_id }).select(:value).all
    assigned_ids.push(issue.assigned_to_id) if issue.assigned_to_id

    worked_ids   = time_entries.collect { |e| e.user_id }
    inactive_ids = assigned_ids.uniq.reject { |id| worked_ids.include?(id) }

    User.where(id: inactive_ids)
  end

  def add_header(sheet)
    sheet.add_row(
    [l(:export_period_from) << " " << Date.strptime(params[:report_start_date], "%Y-%m-%d").strftime("%d.%m.%Y") <<
     " " << l(:export_till) << " " << Date.strptime(params[:report_end_date], "%Y-%m-%d").strftime("%d.%m.%Y")],
    :widths=>[:ignore])

  sheet.add_row([
    l(:export_date), l(:export_is_short), l(:export_description), l(:export_rm_id), l(:export_ot_id), l(:export_status), l(:export_working_hours),
    l(:export_executive), l(:export_company_type), l(:export_department), l(:export_position), l(:export_activity), l(:export_rate)
  ])
  end

  def add_row(sheet, issue, user, hours)
    sheet.add_row([
      issue.custom_field_value(settings[:omnitracker_date_field]),
      issue.custom_field_value(settings[:system_field]),
      issue.subject,
      issue.id,
      issue.custom_field_value(settings[:ot_id_field]),
      issue.status.name,
      hours,
      user.name,
      user_info(user, settings[:internal_company_field]),
      user_info(user, settings[:resource_department_field]),
      user_info(user, settings[:resource_position_field]),
      user_info(user, settings[:resource_activity_field])
    ])
  end
end
