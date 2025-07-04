class CreateWorkflows < ActiveRecord::Migration[8.0]
  def change
    create_table :workflows do |t|
      t.jsonb :schema, null: false
      t.timestamps
    end
  end
end
