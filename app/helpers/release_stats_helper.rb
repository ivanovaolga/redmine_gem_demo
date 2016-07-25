#encoding: utf-8

module ReleaseStatsHelper

  def prom_latency(rls)
    @report.prom_latency(rls) || l(:release_stats_undefined)
  end

  def schedule_accomplishment(rls, phase, gen_date)
    phase_time_used = @report.phase_time_passed(rls, phase, gen_date)
    phase_work_done = @report.phase_completion_lvl(rls, phase, gen_date)

    if phase_time_used.nil? || phase_work_done.nil?
      l(:release_stats_undefined)
    else
      phase_work_done / phase_time_used
    end
  end

  def incident_capacity(rls)
    inc_count = @report.incident_count(rls)
    ts_total = @report.time_spent_total(rls)
    if ts_total == 0
      0
    else
      inc_count / ts_total * 100
    end
  end

  def report_date_field(name)
    content_tag(:div, class: 'report-date-filter') do
      concat calendar_for(name)
      concat label_tag(name, l(name) + ': ')
      concat text_field_tag(name, nil)
    end
  end
end
