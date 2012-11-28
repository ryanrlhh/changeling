module Changeling
  module Models
    class Logling
      include Changeling::Sunspotable

      attr_accessor :klass, :oid, :modifications_json, :before, :after, :modified_at

      Sunspot.setup(self) do
        string :klass, :stored => true
        string :oid, :stored => true
        string :modifications_json, :stored => true
        time :modified_at, :stored => true
      end

      class << self
        def create(object, changes)
          logling = self.new(object, changes)
          logling.save
        end

        def parse_changes(changes)
          before = {}
          after = {}

          changes.each_pair do |attr, values|
            before[attr] = values[0]
            after[attr] = values[1]
          end

          [before, after]
        end

        def klassify(object)
          object.class.to_s.underscore
        end

        def changelogs_for(object, length = nil)
          search = Sunspot.search(self) do
            with :klass, Logling.klassify(object)
            with :oid, object.id.to_s
            order_by :modified_at, :desc
          end

          search.execute!

          if length
            results = search.hits.take(length) if length
          else
            results = search.hits
          end

          results.map { |result| self.new(object, result.stored(:modifications_json), result.stored(:modified_at)) }
        end
      end

      def initialize(object, changes, modified_time = nil)
        # Remove updated_at field.
        changes.delete("updated_at")

        self.klass = Logling.klassify(object)
        self.oid = object.id.to_s
        self.modifications_json = changes

        self.before, self.after = Logling.parse_changes(self.modifications)

        if modified_time
          self.modified_at = modified_time
        else
          if object.respond_to?(:updated_at)
            self.modified_at = object.updated_at
          else
            self.modified_at = Time.now
          end
        end
      end

      def modifications
        JSON.parse(self.modifications_json)
      end

      def save
        Sunspot.index!(self)
      end
    end
  end
end
