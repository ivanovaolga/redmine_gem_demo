module NrdReports
  module Patches
    module SettingsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        def custom_fields_options(formats = nil)
          conditions = { type: 'IssueCustomField' }
          conditions[:field_format] = formats if formats

          CustomField.where(conditions).order(:name).map{ |cf| [cf.name, cf.id] }
        end

        def tracker_options
          Tracker.order(:name).all.map{ |t| [t.name, t.id] }
        end

        def project_options
          Project.active.order(:name).map{ |p| [p.name, p.id] }
        end

        def company_custom_field(name, value)
          field = CustomField.find(@settings[:company_field])
          custom_value = CustomFieldValue.new(custom_field: field, customized: User, value: value)
          field.format.edit_tag(self, '', name, custom_value)
        end

        def estimation_type_field(key)
          select_tag "settings[#{key}]", options_for_select(custom_fields_options([:float, :int]), @settings[key.to_sym])
        end

        def render_estimation_statuses(type)
          html = ''

          statuses =  IssueStatus.where(id: @settings[type])
          html << content_tag('span', id: 'selected-status-names-' + type) do
            statuses.map{ |s| s.name }.join(', ')
          end
          html << content_tag('span', id: 'selected-status-ids-' + type) do
            statuses.each do |s|
              concat hidden_field_tag("settings[#{type}][]", s.id, id: nil)
            end
          end

          html << edit_estimation_statuses_link(type)

          html.html_safe
        end

        def edit_estimation_statuses_link(type)
          link_to '', '#edit', class: 'icon icon-edit edit-estimation-statuses', title: l(:button_edit),
                  data: {type: type}
        end

        def issue_statuses_checkboxes
          html = ''
          IssueStatus.all.each do |s|
            html << content_tag(:label) do
              concat check_box_tag(nil, s.id, false, :id => nil)
              concat s.name
            end
          end

          html.html_safe
        end

        def status_options
          IssueStatus.order(:name).all.map{ |s| [s.name, s.id] }
        end

        def priority_options
          Enumeration.where(type: 'IssuePriority').order(:name).all.map{ |s| [s.name, s.id] }
        end

        def quantum_type_options
          CustomField.find(@settings[:quantum_type_field]).possible_values_options
        end

        def category_options
          CustomField.find(@settings[:resource_category_field]).possible_values_options
        end
      end
    end
  end
end

unless SettingsHelper.included_modules.include?(NrdReports::Patches::SettingsHelperPatch)
  SettingsHelper.send(:include, NrdReports::Patches::SettingsHelperPatch)
end
