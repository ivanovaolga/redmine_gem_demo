module NrdReports
  module Patches
    module CustomFieldsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          unloadable

          alias_method_chain :custom_field_tag,       :disabled_option
          alias_method_chain :custom_field_tag,       :internal_company
          alias_method_chain :custom_field_label_tag, :nrd_required
        end
      end
    end

    module InstanceMethods
      def custom_field_tag_with_disabled_option_old(prefix, custom_value)
        if @issue && !@issue.new_record? && @issue.for_auto_estimate? &&
           custom_value.custom_field_id.to_s == Setting.plugin_nrd_reports[:e_testing_field]

          is_active = @issue.custom_value_for(Setting.plugin_nrd_reports[:req_tester_estimation_field]).try(:true?)

          custom_value.custom_field.format.edit_tag(
            self,
            custom_field_tag_id(prefix, custom_value.custom_field),
            custom_field_tag_name(prefix, custom_value.custom_field),
            custom_value,
            class: "#{custom_value.custom_field.field_format}_cf",
            disabled: !is_active
          )
        else
          custom_field_tag_without_disabled_option(prefix, custom_value)
        end
      end

      def custom_field_tag_with_disabled_option(prefix, custom_value)
        settings = Setting.plugin_nrd_reports
        disabled = @issue && !@issue.new_record? && @issue.for_auto_estimate? &&
                   custom_value.custom_field_id.to_s == settings[:e_testing_field] &&
                   !@issue.custom_value_for(settings[:req_tester_estimation_field]).try(:true?)

        tag = custom_field_tag_without_disabled_option(prefix, custom_value)
        tag.insert(tag.index('>'), ' disabled="disabled"') if disabled
        tag
      end

      def custom_field_tag_with_internal_company(prefix, custom_value)
        tag = custom_field_tag_without_internal_company(prefix, custom_value)
        if @issue.try(:resource?)
          is_company = (custom_value.custom_field.id.to_s == Setting.plugin_nrd_reports[:company_field])
          if is_company
            path = project_issue_form_path(@project, id: @issue, format: 'js')
            tag.insert(tag.index('>'), " data-company='true' data-path='#{path}'")
          end
        end
        tag
      end

      def custom_field_label_tag_with_nrd_required(name, custom_value, options={})
        cf = custom_value.custom_field
        cf.is_required ||= (cf.is_nrd_required && @issue.try(:internal_resource?))
        custom_field_label_tag_without_nrd_required(name, custom_value, options)
      end

    end

  end
end

unless CustomFieldsHelper.included_modules.include?(NrdReports::Patches::CustomFieldsHelperPatch)
  CustomFieldsHelper.send(:include, NrdReports::Patches::CustomFieldsHelperPatch)
end
