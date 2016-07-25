module NrdReports
  module Report
    class ResourceProvision
      unloadable
      include NrdReports::Settings

      attr_accessor :rows

      def initialize(releases, rdp)
        @release_ids = releases.map(&:id)
        @rdp         = rdp

        create_rows
      end

      private

      def create_rows
        @rows = {}
      end

      def filter_release_version(collection)
        collection = collection.where(fixed_version_id: @release_ids) if @release_ids
        collection
      end

      def reworks
        found = Issue.joins(:custom_values)
          .where(tracker_id: settings[:rework_tracker])
          .where('fixed_version_id IS NOT NULL')
          .preload(:custom_values).uniq

        if @rdp
          found = found.where(
            custom_values: {
              custom_field_id: settings[:rdp_field],
              value:           @rdp
            }
          )
        end

        filter_release_version(found)
      end

      def release_issues
        found = Issue.includes(:custom_values).where(tracker_id: settings[:release_tracker])
        filter_release_version(found)
      end

      def release_work_days(release_issue, type)
        work_days_type =
          case type
          when :an
            :work_days_analytics_field
          when :dev
            :work_days_dev_field
          when :test
            :work_days_test_field
          end

        release_issue.custom_field_value(settings[work_days_type]).to_i
      end

      def rework_type(rework)
        if rework.require_analytics?
          :an
        elsif rework.require_development?
          :dev
        elsif rework.require_testing?
          :test
        end
      end

      def calc_rework_required(rework)
        estimation_type =
          if rework.require_analytics?
            :e_analytics_field
          elsif rework.require_development?
            :e_dev_field
          elsif rework.require_testing?
            :e_testing_field
          end

        rework.custom_field_value(settings[estimation_type]).to_f
      end

    end
  end
end
