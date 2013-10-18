class CreatePostJsonDocuments < ActiveRecord::Migration
  def change
    create_table :post_json_documents, id: false do |t|
      t.text :id, null: false, index: true
      t.integer :__doc__version
      t.json :__doc__body
      t.uuid :__doc__model_settings_id
    end

    execute "CREATE UNIQUE INDEX post_json_documents_unique_id ON post_json_documents(id, __doc__model_settings_id);"
    execute "ALTER TABLE post_json_documents ADD PRIMARY KEY (id, __doc__model_settings_id);"
  end
end
