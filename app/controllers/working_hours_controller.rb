class WorkingHoursController < NrdReportsController
  unloadable

  def create

    spent_on_range = params[:report_start_date]..params[:report_end_date]
    issue_ids = TimeEntry.where(spent_on: spent_on_range).pluck(:issue_id)
    @issues = Issue.where(id: issue_ids, tracker_id: settings[:issue_tracker])

    render xlsx: 'report'
  end
end
