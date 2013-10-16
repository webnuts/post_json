class CreatePostJsonModelSettings < ActiveRecord::Migration
  def change
    create_table :post_json_model_settings, id: :uuid do |t|
      t.text :collection_name, index: true, unique: true
      t.json :meta, default: {}, null: false
      t.boolean :use_timestamps, default: true
      t.text :created_at_attribute_name, default: 'created_at', null: false
      t.text :updated_at_attribute_name, default: 'updated_at', null: false
      t.boolean :include_version_number, default: true
      t.text :version_attribute_name, default: 'version', null: false
      t.boolean :use_dynamic_index, default: true
      t.integer :create_dynamic_index_milliseconds_threshold, default: 50
      t.timestamps
    end

    execute "CREATE INDEX post_json_model_settings_lower_collection_name ON post_json_model_settings(lower(collection_name));"
  end
end
