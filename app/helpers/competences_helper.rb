module CompetencesHelper
  def system_custom_field
    field = CustomField.find(Setting.plugin_nrd_reports[:system_field])
    custom_value = CustomFieldValue.new(custom_field: field, customized: Issue, value: @system)
    field.format.edit_tag(self, :system, :system, custom_value)
  end
end
