module Changeling
  module Support
    class Search
      def self.find_by(args)
        return [] unless args.kind_of?(Hash)

        filters = args[:filters]
        sort = args[:sort]
        return [] unless filters || sort

        size = args[:size] || 10

        @class = Changeling::Models::Logling
        @class.__elasticsearch__.refresh_index!(index: @class.index_name)

        results = @class.search nil, {index: @class.index_name} do
          query do
            filtered do
              query { all }
              filters.each do |f|
                filter :terms, { f.first[0].to_sym => [f.first[1].to_s] }
              end
            end
          end

          sort { by sort[:field], sort[:direction].to_s }
        end.results

        # Some apps may return Response::Response objects in results instead of Changeling objects.
        results.map { |result|
          if result.class == @class
            result
          elsif result.class == Response::Response
            @class.new(JSON.parse(result.to_json))
          elsif result.class == Hash
            @class.new(result)
          end
        }
      end
    end
  end
end
