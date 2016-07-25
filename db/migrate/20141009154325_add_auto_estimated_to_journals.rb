class AddAutoEstimatedToJournals < ActiveRecord::Migration
  def change
    add_column :journals, :auto_estimated, :boolean, default: false
  end
end
