module NrdReports
  module Patches
    module IssuesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable
          alias_method_chain :show_detail, :auto_estimation

          def system_knowledge_row(n, knowledge = nil)
            content_tag(:p, class: 'system-knowledge-row') do
              concat label_tag '', required_field_label(l(:field_system))
              concat system_field_tag(n, knowledge)

              concat label_tag 'system_knowledge[value]', required_field_label(l(:field_system_knowledge)),
                               class: 'system-knowledge-label'
              concat text_field_tag "system_knowledge[#{n}][value]", knowledge.try(:value), class: 'system-knowledge-value'
              concat content_tag(:span, content_tag(:strong, ' %'))
              concat link_to '', '#delete', class: 'icon icon-del delete-knowledge'
            end
          end

          private

          def system_field_tag(n, knowledge = nil)
            field = CustomField.find(Setting.plugin_nrd_reports[:system_field])
            custom_value = CustomFieldValue.new(custom_field: field, customized: User, value: knowledge.try(:system))
            field.format.edit_tag(self, '', "system_knowledge[#{n}][system]", custom_value)
          end

          def required_field_label(content)
            (content + content_tag(:span, ' *', class: 'required')).html_safe
          end
        end
      end

      module InstanceMethods
        def show_detail_with_auto_estimation(detail, no_html=false, options={})
          msg = show_detail_without_auto_estimation(detail, no_html, options)
          if detail.journal.try(:auto_estimated)
            msg << ' ' << l(:detail_auto_estimated)
          end
          msg
        end
      end

    end
  end
end

unless IssuesHelper.included_modules.include?(NrdReports::Patches::IssuesHelperPatch)
  IssuesHelper.send(:include, NrdReports::Patches::IssuesHelperPatch)
end
