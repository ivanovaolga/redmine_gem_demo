module ReleaseCalendarsHelper
  def analytics_period(issue)
    start_date = issue.custom_field_value(settings[:release_analytics_start_field])
    end_date   = issue.custom_field_value(settings[:release_dev_start_field])
    release_period(start_date, end_date)
  end

  def dev_period(issue)
    start_date = issue.custom_field_value(settings[:release_dev_start_field])
    end_date   = issue.custom_field_value(settings[:release_test_start_field])
    release_period(start_date, end_date)
  end

  def test_period(issue)
    start_date = issue.custom_field_value(settings[:release_test_start_field])
    end_date   = issue.custom_field_value(settings[:release_btest_start_field])
    release_period(start_date, end_date)
  end

  def btest_period(issue)
    start_date = issue.custom_field_value(settings[:release_btest_start_field])
    journal = issue.journals.joins(:details).where(
      journal_details: { property: :attr, prop_key: :status_id, value: settings[:release_closed_status] }
    ).last

    release_period(start_date, journal.try(:created_on).to_s)
  end

  private

  def release_period(start_date, end_date)
    start_date  &&= format_date(start_date.to_date)
    end_date    &&= format_date(end_date.to_date)

    (start_date.to_s + ' - ' + end_date.to_s) if start_date || end_date
  end
end
