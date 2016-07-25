class ReleaseStatsController < NrdReportsController
  unloadable

  def create
    @report = NrdReports::Report::ReleaseStats.new(settings, @logger)
    @gen_date = Time.parse(params[:report_date])
    render xlsx: 'report'
  end
end
