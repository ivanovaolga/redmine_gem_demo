class ReworkResourcesController < NrdReportsController
  unloadable

  before_filter :set_releases

  def create
    @report = NrdReports::Report::ReworkResources.new(@releases, params)

    render xlsx: 'report'
  end
end
