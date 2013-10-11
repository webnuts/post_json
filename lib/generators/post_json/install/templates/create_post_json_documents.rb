class CreatePostJsonDocuments < ActiveRecord::Migration
  def change
    create_table :post_json_documents, id: :text do |t|
      t.integer :__doc__version
      t.json :__doc__body
      t.uuid :__doc__collection_id
    end

    execute "ALTER TABLE post_json_documents ADD PRIMARY KEY (id)"
  end
end
