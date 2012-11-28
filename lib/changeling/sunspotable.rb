module Changeling
  module Sunspotable
    # If having trouble with the Solr schema, get the latest from https://raw.github.com/sunspot/sunspot/master/sunspot_solr/solr/solr/conf/schema.xml and replace whatever is in /usr/local/var/solr/solr/conf/schema.xml

    def self.included(base)
      base.class_eval do
        Sunspot::Adapters::DataAccessor.register(DataAccessor, base)
        Sunspot::Adapters::InstanceAdapter.register(InstanceAdapter, base)
      end
    end

    class InstanceAdapter < Sunspot::Adapters::InstanceAdapter
      def id
        # To almost guarantee no two IDs are the same and that everything is separately indexed
        Digest::MD5.hexdigest(@instance.oid + @instance.modified_at.to_s + rand(1000000).to_s)
      end
    end

    class DataAccessor < Sunspot::Adapters::DataAccessor
      def load(id)
        nil
      end

      def load_all(ids)
        nil
      end
    end
  end
end
