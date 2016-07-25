module NrdReports
  module Patches
    module IssuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          has_many :system_knowledge, dependent: :destroy, validate: false

          has_one :resource_category, class_name: 'CustomValue', as: :customized, validate: false, conditions: proc {
            {custom_field_id: Setting.plugin_nrd_reports[:resource_category_field]}
          }

          has_one :resource_company, class_name: 'CustomValue', as: :customized, validate: false, conditions: proc {
            {custom_field_id: Setting.plugin_nrd_reports[:company_field]}
          }

          has_one :resource_volume, class_name: 'CustomValue', as: :customized, validate: false, conditions: proc {
            {custom_field_id: Setting.plugin_nrd_reports[:resource_value]}
          }

          validate :validate_system_knowledge, if: :resource?
        end
      end

      module InstanceMethods
        def estimate_auto!(manual_dev_e = nil, manual_tester_e = nil)
          settings = Setting.plugin_nrd_reports

          return unless for_auto_estimate?

          init_auto_estimated_journal

          manual_dev_e    = custom_value_for(settings[:req_dev_estimation_field]).try(:true?)    if manual_dev_e.nil?
          manual_tester_e = custom_value_for(settings[:req_tester_estimation_field]).try(:true?) if manual_tester_e.nil?

          return if manual_dev_e && manual_tester_e

          if require_analytics?
            a_estimate_val  = custom_value_for(settings[:e_analytics_field])
            a_estimate      = a_estimate_val.custom_field.cast_value(a_estimate_val.value)
          else
            a_estimate = subtasks_spent_hours(settings[:subtask_analytics_tracker])
          end

          return if a_estimate.nil? || a_estimate.zero?

          if manual_dev_e
            if require_development?
              dev_estimate_val  = custom_value_for(settings[:e_dev_field])
              dev_estimate      = dev_estimate_val.custom_field.cast_value(dev_estimate_val.value)
            else
              dev_estimate = subtasks_spent_hours(settings[:subtask_dev_tracker])
            end
          else
            dev_estimate = a_estimate * 1.5
            self.custom_field_values = { settings[:e_dev_field] => dev_estimate }
          end

          unless manual_tester_e || dev_estimate.nil?
            test_estimate = dev_estimate * 1.5
            self.custom_field_values = { settings[:e_testing_field] => test_estimate }
          end

          res = custom_field_values_changed?
          save_custom_field_values
          create_journal

          res
        end

        def for_auto_estimate?
          tracker_id.to_s == Setting.plugin_nrd_reports[:estimation_tracker]
        end

        def resource?
          tracker_id.to_s == Setting.plugin_nrd_reports[:resource_tracker]
        end

        def internal_resource?
          if resource?
            company = custom_field_value(Setting.plugin_nrd_reports[:company_field])
            company == Setting.plugin_nrd_reports[:internal_company]
          end
        end

        def update_required_cf
          custom_field_values.each do |v|
            v.custom_field.is_required ||= v.custom_field.is_nrd_required && internal_resource?
          end
        end

        def require_analytics?
          analytics_statuses = Setting.plugin_nrd_reports[:e_analytics_statuses]
          analytics_statuses.include?(status_id.to_s) if analytics_statuses
        end

        def require_development?
          dev_statuses = Setting.plugin_nrd_reports[:e_dev_statuses]
          dev_statuses.include?(status_id.to_s) if dev_statuses
        end

        def require_testing?
          test_statuses = Setting.plugin_nrd_reports[:e_testing_statuses]
          test_statuses.include?(status_id.to_s) if test_statuses
        end

        private

        def subtasks_spent_hours(tracker_id)
          descendants.where(tracker_id: tracker_id).joins(:time_entries)
            .sum("#{TimeEntry.table_name}.hours").to_f || 0.0
        end

        def init_auto_estimated_journal
          @current_journal = nil
          init_journal(User.current)
          @current_journal.auto_estimated = true if @current_journal
        end

        def validate_system_knowledge
          systems = system_knowledge.map(&:system)
          system_knowledge.each do |sk|
            unless systems.one? { |s| s == sk.system }
              errors.add(:base, I18n.t(:error_system_knoledge_exists, sys: sk.system))
              systems.slice!(systems.index(sk.system))
            end

            sk.errors.full_messages.each { |m| errors.add(:base, m) } unless sk.valid?
          end
        end
      end

    end
  end
end

unless Issue.included_modules.include?(NrdReports::Patches::IssuePatch)
  Issue.send(:include, NrdReports::Patches::IssuePatch)
end
