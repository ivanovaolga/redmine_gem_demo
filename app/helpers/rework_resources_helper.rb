module ReworkResourcesHelper
  def report_categories_options
    CustomField.find(settings[:resource_category_field]).possible_values_options
  end

  def report_companies_options
    CustomField.find(settings[:company_field]).possible_values_options
  end

  def report_systems
    CustomField.find(settings[:system_field]).possible_values
  end

  def column_widths(systems)
    [:auto] + [15] * 4 + [10] * systems.size + [15] * 4
  end

  def sum_columns(sum_row)
    sum_row.transpose.map! { |arr| arr.inject{ |sum, v| v.blank? ? sum : sum.to_f + v } }
  end
end
