class CreateCompetences < ActiveRecord::Migration
  def change
    create_table :competences do |t|
      t.string  :system,  null: false
      t.integer :month,   null: false
      t.decimal :value,   null: false, precision: 5, scale: 2

      t.timestamps
    end

    add_index :competences, :system
  end
end
