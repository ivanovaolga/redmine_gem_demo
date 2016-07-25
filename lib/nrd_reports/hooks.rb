module NrdReports
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom, partial: 'issues/system_knowledge_form'
    render_on :view_issues_show_details_bottom, partial: 'issues/system_knowledge_show'

    def view_layouts_base_html_head(context={})
      stylesheet_link_tag('nrd_reports', plugin: 'nrd_reports') +
      javascript_include_tag('nrd_reports', plugin: 'nrd_reports')
    end

    def controller_issues_edit_after_save(context={})
      context[:issue].estimate_auto!
    end

    def controller_issues_new_after_save(context={})
      context[:issue].estimate_auto!
    end

    def controller_issues_edit_before_save(context={})
      context[:issue].update_required_cf

      if context[:issue].resource? && context[:params][:system_knowledge].present?
        context[:issue].system_knowledge = []
        context[:params][:system_knowledge].each_value do |p|
          context[:issue].system_knowledge << SystemKnowledge.new(p)
        end
      end
    end

    def controller_issues_new_before_save(context={})
      context[:issue].update_required_cf

      if context[:issue].resource? && context[:params][:system_knowledge].present?
        context[:params][:system_knowledge].each_value do |p|
          context[:issue].system_knowledge << SystemKnowledge.new(p)
        end
      end
    end
  end
end
