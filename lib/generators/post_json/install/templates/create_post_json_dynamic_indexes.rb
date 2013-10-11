class CreatePostJsonDynamicIndexes < ActiveRecord::Migration
  def change
    create_table :post_json_dynamic_indexes, id: :uuid do |t|
      t.text :selector, index: true, null: false
      #t.text :index_name, index: true, null: false
      t.uuid :collection_id, index: true
      t.timestamps
    end
  end
end
