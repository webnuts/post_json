module PostJson
  module Copyable
    extend ActiveSupport::Concern

    module ClassMethods
      def copy(destination_collection_name)
        destination = Collection[destination_collection_name]
        if exists?
          src_id = persisted_settings.id

          if destination.persisted?
            dest_id = destination.persisted_settings.id
            query = all_without_query_translator
            query = query.joins("INNER JOIN #{table_name} as dest ON dest.id = #{table_name}.id")
            query = query.where("dest.__doc__model_settings_id = '#{dest_id}'")
            query = query.where("\"#{table_name}\".__doc__model_settings_id = '#{src_id}'")
            query = query.where("dest.id = \"#{table_name}\".id")
            conflicting_ids = query.pluck("dest.id").join(", ")
            if conflicting_ids.present?
              error_message = "Following primary keys (#{primary_key}) already exists in collection \"#{destination.collection_name}\": #{conflicting_ids}."
              raise ActiveRecord::RecordNotUnique, error_message
            end
          end

          dest_id = destination.persisted_settings.id
          selectors = PostJson::Base.column_names.map { |s| s == "__doc__model_settings_id" ? "'#{dest_id}' as #{s}" : s }.join(", ")
          condition = "__doc__model_settings_id = '#{src_id}'"
          destination.transaction do
            destination.connection.execute("INSERT INTO #{table_name} (SELECT #{selectors} FROM #{table_name} WHERE #{condition})")
          end
        end
        destination
      end
    end
  end
end
