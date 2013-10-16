class CreatePostJsonDynamicIndexes < ActiveRecord::Migration
  def change
    create_table :post_json_dynamic_indexes, id: :uuid do |t|
      t.text :selector, index: true, null: false
      t.uuid :model_settings_id, index: true
      t.timestamps
    end
  end
end
