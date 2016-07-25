class CreateSystemKnowledge < ActiveRecord::Migration
  def change
    create_table :system_knowledge do |t|
      t.string  :system,   null: false
      t.integer :value,    null: false
      t.integer :issue_id, null: false

      t.timestamps
    end

    add_index :system_knowledge, :issue_id
  end
end
