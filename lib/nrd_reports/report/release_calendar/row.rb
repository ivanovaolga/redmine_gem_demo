module NrdReports
  module Report
    class ReleaseCalendar::Row
      include Redmine::I18n

      attr_reader :issue, :settings
      def initialize(issue, settings)
        @issue, @settings = issue, settings
      end

      def fixed_version_name
        issue.fixed_version.name
      end

      def analytics_period
        start_date = issue.custom_field_value(settings[:release_analytics_start_field])
        end_date   = issue.custom_field_value(settings[:release_dev_start_field])
        release_period(start_date, end_date)
      end

      def dev_period
        start_date = issue.custom_field_value(settings[:release_dev_start_field])
        end_date   = issue.custom_field_value(settings[:release_test_start_field])
        release_period(start_date, end_date)
      end

      def test_period
        start_date = issue.custom_field_value(settings[:release_test_start_field])
        end_date   = issue.custom_field_value(settings[:release_btest_start_field])
        release_period(start_date, end_date)
      end

      def btest_period
        start_date = issue.custom_field_value(settings[:release_btest_start_field])
        journal = issue.journals.joins(:details).where(
          journal_details: { property: :attr, prop_key: :status_id, value: settings[:release_closed_status] }
        ).last

        release_period(start_date, journal.try(:created_on).to_s)
      end

      def field(name)
        issue.custom_field_value(settings[name])
      end

      def to_worksheet_row
        [ fixed_version_name,
          analytics_period,
          field(:work_days_analytics_field),
          dev_period,
          field(:work_days_dev_field),
          test_period,
          field(:work_days_test_field),
          btest_period,
          field(:work_days_btest_field) ]
      end

      protected

      def release_period(start_date, end_date)
        start_date  &&= format_date(start_date.to_date)
        end_date    &&= format_date(end_date.to_date)

        (start_date.to_s + ' - ' + end_date.to_s) if start_date || end_date
      end

    end
  end
end
