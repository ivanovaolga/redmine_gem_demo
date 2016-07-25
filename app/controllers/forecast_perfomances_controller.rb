class ForecastPerfomancesController < NrdReportsController
  before_filter :set_releases

  def new; end

  def create
    @report = NrdReports::Report::ForecastPerfomances.new(params, settings)
    @releases_report = @report.releases_report(@releases)
    @systems_report = @report.systems_report(@releases)
    render xlsx: 'report'
  end
end
