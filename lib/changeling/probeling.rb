module Changeling
  module Probeling
    def all_history
      Changeling::Models::Logling.changelogs_for(self)
    end

    def history(records = 10)
      Changeling::Models::Logling.changelogs_for(self, records.to_i)
    end
  end
end
