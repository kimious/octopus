class CreateBlobs < ActiveRecord::Migration[8.0]
  def change
    create_table :blobs do |t|
      t.string :kind, null: false, index: true
      t.jsonb :metadata, null: false, default: '{}'
      t.text :value, null: false
      t.timestamps
    end
  end
end
