module PostJson
  class ModelSettings < ActiveRecord::Base
    self.table_name = "post_json_model_settings"

    before_validation do |settings|
      settings.collection_name = settings.collection_name.to_s.strip
    end

    scope :by_collection, ->(name) { where("lower(collection_name) = ?", name.to_s.strip.downcase) }

    class << self
      def collection_name_digest(name)
        Digest::MD5.hexdigest(name.to_s.strip.downcase)
      end
    end
  end
end