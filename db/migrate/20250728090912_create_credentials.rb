class CreateCredentials < ActiveRecord::Migration[8.0]
  def change
    create_table :credentials do |t|
      t.string :kind, null: false, index: true
      t.text :data, null: false
      t.timestamps
    end
  end
end
