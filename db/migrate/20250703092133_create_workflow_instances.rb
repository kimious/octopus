class CreateWorkflowInstances < ActiveRecord::Migration[8.0]
  def change
    create_table :workflow_instances do |t|
      t.references :workflow, foreign_key: true, index: true, null: false
      t.jsonb :schema, null: false
      t.string :status, null: false, index: true
      t.jsonb :state, null: false
      t.jsonb :context, null: false
      t.jsonb :args, null: false, default: '{}'
      t.timestamps
    end
  end
end
