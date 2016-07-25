module NrdReports
  module Report
    class ForecastPerfomances
      attr_reader :params, :settings

      def initialize(params = {}, settings = {})
        @params, @settings = params, settings
      end

      def release_calendar
        @release_calendar ||= NrdReports::Report::ReleaseCalendar.new(release_calendar_issues, settings)
      end

      def competence
        Competence.order("system asc").group_by(&:system)
      end

      def releases_report(releases)
        @releases_report ||= NrdReports::Report::ResourceProvision::Releases.new(releases, params[:rdp])
      end

      def systems_report(releases)
        @systems_report ||= NrdReports::Report::ResourceProvision::Systems.new(
          releases,
          params[:rdp],
          NrdReports::Report::ReworkResources.new(releases)
        )
      end

      protected

      def release_calendar_issues
        @release_calendar_issues ||= Issue.includes(:custom_values, :fixed_version)
          .where(tracker_id: settings[:release_tracker])
          .where('fixed_version_id IS NOT NULL').tap do |i|
          i.merge(Issue.where(fixed_version_id: params[:releases])) if params[:releases]
        end
      end

    end
  end
end
