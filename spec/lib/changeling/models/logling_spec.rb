require (File.expand_path('../../../../spec_helper', __FILE__))

describe Changeling::Models::Logling do
  before(:all) do
    @klass = Changeling::Models::Logling
  end

  # .models is defined in spec_helper.
  models.each_pair do |model, args|
    puts "Testing #{model} now."

    before(:each) do
      @object = model.new(args[:options])
      @modifications = args[:changes]
      @modifications_json = @modifications.to_json

      @logling = @klass.new(@object, @modifications_json)
    end

    context "Class Methods" do
      describe ".create" do
        before(:each) do
          @object.stub(:changes).and_return(@modifications)

          @klass.should_receive(:new).with(@object, @modifications_json).and_return(@logling)
        end

        it "should call new with it's parameters then save the initialized logling" do
          @logling.should_receive(:save)

          @klass.create(@object, @modifications_json)
        end
      end

      describe ".new" do
        before(:each) do
          @before, @after = @klass.parse_changes(@modifications)
        end

        it "should set klass as the .klassify-ed name" do
          @logling.klass.should == @klass.klassify(@object)
        end

        it "should set oid as the stringified object's ID" do
          @logling.oid.should == @object.id.to_s
        end

        it "should set the modifications as the incoming changes parameter" do
          @logling.modifications.should == @modifications
        end

        it "should set before and after based on .parse_changes" do
          @logling.before.should == @before
          @logling.after.should == @after
        end

        it "should set modified_at to the passed in time if one is given" do
          @object.stub(:updated_at).and_return(true)

          # Setting up a variable to prevent test flakiness from passing time.
          time = Time.now
          @object.stub(:updated_at).and_return(time + 1.day)

          # Create a new logling to trigger the initialize method
          @logling = @klass.new(@object, @modifications_json, time)
          @logling.modified_at.should_not == @object.updated_at
          @logling.modified_at.should == time
        end

        it "should set modified_at to the object's time of update if the object responds to the updated_at method" do
          @object.should_receive(:respond_to?).with(:updated_at).and_return(true)

          # Setting up a variable to prevent test flakiness from passing time.
          time = Time.now
          @object.stub(:updated_at).and_return(time)

          # Create a new logling to trigger the initialize method
          @logling = @klass.new(@object, @modifications_json)
          @logling.modified_at.should == @object.updated_at
        end

        it "should set modified_at to the current time if the object doesn't respond to updated_at" do
          @object.should_receive(:respond_to?).with(:updated_at).and_return(false)

          # Setting up a variable to prevent test flakiness from passing time.
          time = Time.now
          Time.stub(:now).and_return(time)

          # Create a new logling to trigger the initialize method
          @logling = @klass.new(@object, @modifications_json)
          @logling.modified_at.should == time
        end
      end

      describe ".klassify" do
        it "should stringify and underscore the object's class name" do
          @klass.klassify(@object).should == @object.class.to_s.underscore
        end
      end

      describe ".parse_changes" do
        before(:each) do
          @object.save!

          @before = @object.attributes.select { |attr| @modifications.keys.include?(attr) }

          @modifications.each_pair do |k, v|
            @object.send("#{k}=", v[1])
          end

          @after = @object.attributes.select { |attr| @modifications.keys.include?(attr) }
        end

        it "should correctly match the before and after states of the object" do
          @klass.parse_changes(@object.changes).should == [@before, @after]
        end
      end

      describe ".changelogs_for" do
        context "Search Parameters" do
          before(:each) do
            @klass.changelogs_for(@object)
          end

          it "should perform a search for Loglings" do
            Sunspot.session.should be_a_search_for(@klass)
          end

          it "should perform a search for the klass" do
            Sunspot.session.should have_search_params(:with, :klass, @klass.klassify(@object))
          end

          it "should perform a search for the oid" do
            Sunspot.session.should have_search_params(:with, :oid, @logling.oid)
          end

          it "should order the search results by dsecending modified_at" do
            Sunspot.session.should have_search_params(:order_by, :modified_at, :desc)
          end
        end

        context "Search Execution", :search => true do
          before(:each) do
            @logling.save
            klass = @logling.klass
            oid = @logling.oid

            @search = Sunspot.search(@klass) do
              with :klass, klass
              with :oid, oid
              order_by :modified_at, :desc
            end

            Sunspot.should_receive(:search).and_return(@search)

            @search.execute
            @results = @search.hits
            @search.should_receive(:hits).and_return(@results)
          end

          context "general" do
            it "should execute the search", :solr => true do
              @search.should_receive(:execute)
            end

            it "should iterate through the results and create Loglings" do
              @results.each do |result|
                @klass.should_receive(:new).with(@object, result.stored(:modifications_json), result.stored(:modified_at))
              end
            end

            after(:each) do
              @klass.changelogs_for(@object)
            end
          end

          context "length option" do
            it "should find the specified amount of entries if length option is passed" do
              num = 5
              @results.should_receive(:take).with(num).and_return(@results)
              @klass.changelogs_for(@object, num)
            end

            it "should find all entries if length option is not passed" do
              @results.should_not_receive(:take)
              @klass.changelogs_for(@object)
            end
          end
        end
      end
    end

    context "Instance Methods" do
      describe ".save" do
        it "should index itself into Solr" do
          Sunspot.should_receive(:index!).with(@logling)
        end

        after(:each) do
          @logling.save
        end
      end
    end
  end
end
