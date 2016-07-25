class AddIsNrdRequiredToCustomField < ActiveRecord::Migration
  def change
    add_column :custom_fields, :is_nrd_required, :boolean, default: false
  end
end
