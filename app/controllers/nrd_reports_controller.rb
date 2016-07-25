class NrdReportsController < ApplicationController
  helper :resource_reports
  helper NrdReports::XlsExportHelper

  before_filter :authorize_global

  private

  def possible_releases
    tracker = Tracker.find_by_id(settings[:release_tracker])
    tracker ? tracker.projects.map { |p| p.shared_versions }.flatten : []
  end
  helper_method :possible_releases

  def settings
    @settings ||= Setting.plugin_nrd_reports
  end
  helper_method :settings

  def set_releases
    @releases = params[:releases].blank? ? possible_releases : Version.where(id: params[:releases])
  end
end
