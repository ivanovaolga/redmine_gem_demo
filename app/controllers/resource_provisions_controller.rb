class ResourceProvisionsController < NrdReportsController
  unloadable

  before_filter :set_releases

  def create
    rdp = params[:rdp]

    @releases_report = NrdReports::Report::ResourceProvision::Releases.new(@releases, rdp)
    resources_report = NrdReports::Report::ReworkResources.new(@releases)
    @systems_report  = NrdReports::Report::ResourceProvision::Systems.new(@releases, rdp, resources_report)
    @stages_report   = NrdReports::Report::ResourceProvision::Stages.new(@releases, rdp, @systems_report)

    render xlsx: 'report'
  end
end
