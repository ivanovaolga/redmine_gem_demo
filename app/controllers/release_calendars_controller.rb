class ReleaseCalendarsController < NrdReportsController
  unloadable

  def create
    @issues = Issue.includes(:custom_values, :fixed_version)
      .where(tracker_id: settings[:release_tracker])
      .where('fixed_version_id IS NOT NULL')

    @issues = @issues.where(fixed_version_id: params[:releases]) if params[:releases]
    @report = NrdReports::Report::ReleaseCalendar.new(@issues, settings)

    render xlsx: 'report'
  end

end
