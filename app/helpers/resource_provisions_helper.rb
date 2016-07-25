module ResourceProvisionsHelper
  def report_composition_date
    format_date(Date.today)
  end

  def rdp_options
    CustomField.find(settings[:rdp_field]).possible_values_options
  end
end
