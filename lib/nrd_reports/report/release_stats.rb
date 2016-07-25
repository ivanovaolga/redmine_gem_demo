#encoding: utf-8

module NrdReports
  module Report
    class ReleaseStats
      LOG_DIR = 'log/rls_stats.log'

      attr_reader :params, :settings

      def initialize(settings = {}, logger)
        @settings = settings
        @logger = Logger.new(File.open(Rails.root.join(LOG_DIR), 'a', sync: true))
    	@logger.formatter = Logger::Formatter.new
      end

      def time_spent_total(rls)
	    system_modifications(rls).reduce(0) do|memo, sm|
	      amount = sm.self_and_descendants.joins(:time_entries).sum(:hours).to_f || 0.0
	      memo += amount
	    end
	  end

      def phase_time_passed(rls, phase, report_date)
	    case phase
	    when :anlz
	      phase_end = Time.parse(rls.custom_value_for(settings[:rls_stats_dev_start_field]).value)
	      if rls.custom_value_for(settings[:rls_stats_anlz_start_field]).nil?
	        phase_start = phase_end - settings[:rls_stats_default_anlz_length].to_i.days
	      else
	        phase_start = Time.parse(rls.custom_value_for(settings[:rls_stats_anlz_start_field]).value)
	      end
	    when :dev
	      phase_start = Time.parse(rls.custom_value_for(settings[:rls_stats_dev_start_field]).value)
	      phase_end   = Time.parse(rls.custom_value_for(settings[:rls_stats_test_start_field]).value)
	    when :test
	      phase_start = Time.parse(rls.custom_value_for(settings[:rls_stats_test_start_field]).value)
	      phase_end   = Time.parse(rls.custom_value_for(settings[:rls_stats_prod_start_field]).value)
	    else
	      phase_start = nil
	      phase_end   = nil
	    end

	    phase_length  = (phase_end - phase_start).to_i / 1.day
	    passed_period = (report_date - phase_start + 1.day).to_i / 1.day

	    @logger.info "time_spent_total rls: #{rls.subject}"
	    @logger.info "phase: #{phase}, start: #{phase_start}, end: #{phase_end}, report_date: #{report_date}"
	    @logger.info "phase_length: #{phase_length}, passed_period: #{passed_period}, ratio:#{passed_period/phase_length}"

	    passed_period.to_f / phase_length
	  rescue
	    nil
	  end

	  def phase_completion_lvl(rls, phase, report_date=nil)
	    case phase
	    when :anlz
	      tracker_id = settings[:rls_stats_anlz_tracker]
	      status_id  = settings[:rls_stats_anlz_complete_status]
	      estimation_fld_id = settings[:rls_stats_e_anlz_field]
	      report_date ||= Time.parse(rls.custom_value_for(settings[:rls_stats_dev_start_field]).value)
	    when :dev
	      tracker_id = settings[:rls_stats_dev_tracker]
	      status_id  = settings[:rls_stats_dev_complete_status]
	      estimation_fld_id = settings[:rls_stats_e_dev_field]
	      report_date ||= Time.parse(rls.custom_value_for(settings[:rls_stats_test_start_field]).value)
	    when :test
	      tracker_id = settings[:rls_stats_test_tracker]
	      status_id  = settings[:rls_stats_test_complete_status]
	      estimation_fld_id = settings[:rls_stats_e_test_field]
	      report_date ||= Time.parse(rls.custom_value_for(settings[:rls_stats_prod_start_field]).value)
	    else
	      # raise some exception?
	      tracker_id = 0
	      status_id  = 0
	      estimation_fld_id = 0
	      report_date = Time.parse("1900-01-01")
	    end
	    report_date = report_date.end_of_day

	    sys_mods = system_modifications(rls)

	    @logger.info "*** phase_completion_lvl for #{phase}"
	    phase_capacity = 0
	    time_spent = 0
	    sys_mods.each do |sm|
	      status_change_jr = sm.journals.joins(:details).where(
	        journal_details: {
	          prop_key: "status_id",
	          value: status_id
	        }
	        ).select(:created_on).order("journals.created_on desc").first

	      ts = spent_on_date(sm, tracker_id, report_date)
	      time_spent += ts

	      if !status_change_jr.nil? && status_change_jr.created_on <= report_date
	        phase_capacity += ts
	      elsif !sm.custom_value_for(estimation_fld_id).nil?
	        phase_capacity += sm.custom_value_for(estimation_fld_id).value.to_f
	      end
	      @logger.info "phase_capacity: #{phase_capacity}, time_spent: #{time_spent}"
	    end

	    phase_capacity == 0 ? 0 : time_spent / phase_capacity * 100
	  rescue
	    nil
	  end

	  def spent_on_date(issue, tracker_id, report_date)
	    @logger.info "tracker_id: #{tracker_id}"

	    issue.children.where(tracker_id: tracker_id).reduce(0) do |memo, iss|
	      amount = iss.self_and_descendants.joins(:time_entries)
	        .where(time_entries: {created_on: "1900-01-01"..report_date.strftime("%Y-%m-%d")})
	        .sum(:hours).to_f || 0.0
	      memo += amount
	    end
	  end

	  def system_modifications(rls)
	    sm = Issue.joins(:custom_values).where(
	      fixed_version_id: rls.fixed_version.id,
	      custom_values: {
	        custom_field_id: settings[:rls_stats_rls_negotiation_field],
	        value: ["Разработка согласована", "Разработка согласована(RM)", "Тестирование согласовано"]
	      }
	     ).all
	  end

	  def incident_count(rls)
	    pd_fact = prom_date_fact rls
	    return 0 if pd_fact.nil?

	    inc_num = Issue.where(
	      tracker_id: settings[:rls_stats_incident_tracker],
	      priority_id: settings[:rls_stats_inc_priority_ids],
	      created_on: pd_fact..(pd_fact + 1.week)
	    ).count
	  end

	  def prom_latency(rls)
	    pd_planned = prom_date_planned(rls)
	    pd_fact = prom_date_fact(rls)

	    @logger.info "pd_planned: #{pd_planned.change(hour: 0, min: 0, sec: 0)}"
	    @logger.info "pd_fact: #{pd_fact.change(hour: 0, min: 0, sec: 0)}"

	    if pd_planned.nil? || pd_fact.nil?
	      return nil
	    else
	      return (pd_fact - pd_planned).to_i / 1.day
	    end
	  end

	  def prom_date_planned(rls)
	    pd_planned = rls.custom_value_for settings[:rls_stats_prod_start_field]
	    Time.parse(pd_planned.value).at_midnight if pd_planned.present?
	  end

	  def prom_date_fact(rls)
	    jr = rls.journals.joins(:details).where(
	    	journal_details: {
	    		prop_key: "status_id",
	    		value: settings[:rls_stats_status_installed]
	    	}
	    ).first
	    jr.created_on.at_midnight if jr.present?
	  end

	  def last_release_in_status(gen_date, status_id)

	    @logger.info "*** last_release_in_status - gen_date: #{gen_date}; status_id: #{status_id}"

	    Issue.joins(journals: :details)
	      .where("issues.tracker_id = ?
	        AND journal_details.prop_key = 'status_id'
	        AND journal_details.value = ?
	        AND issues.subject NOT LIKE '%patch%'
	        AND (journals.created_on <= ?) ",
	        settings[:release_tracker], status_id, gen_date)
	      .order("journals.created_on desc").first
	  end

	  def first_release_in_analitics(gen_date)
	    Issue.where(
	      status_id: settings[:rls_stats_rls_negotiation_field]
	      ).order("id asc").first
	  end
    end
  end
end
