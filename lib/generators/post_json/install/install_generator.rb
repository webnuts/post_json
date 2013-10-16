require 'rails/generators/migration'

module PostJson
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path('../templates', __FILE__)
      desc "add the migrations"

      def self.next_migration_number(path)
        unless @prev_migration_nr
          @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
        else
          @prev_migration_nr += 1
        end
        @prev_migration_nr.to_s
      end

      def copy_migrations
        migration_template "enable_extensions.rb", "db/migrate/enable_extensions.rb"
        migration_template "create_procedures.rb", "db/migrate/create_procedures.rb"
        migration_template "create_post_json_model_settings.rb", "db/migrate/create_post_json_model_settings.rb"
        migration_template "create_post_json_collections.rb", "db/migrate/create_post_json_collections.rb"
        migration_template "create_post_json_documents.rb", "db/migrate/create_post_json_documents.rb"
        migration_template "create_post_json_dynamic_indexes.rb", "db/migrate/create_post_json_dynamic_indexes.rb"
      end

      def copy_initializer_file
        copy_file "initializer.rb", "config/initializers/post_json.rb"
      end
    end
  end
end