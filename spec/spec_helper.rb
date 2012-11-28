require(File.expand_path('../../lib/changeling', __FILE__))
require 'mongoid'
require 'sunspot'
require 'sunspot_matchers'
require 'sunspot-rails-tester'
require 'database_cleaner'

# Fixtures
Dir[File.dirname(__FILE__) + "/fixtures/**/*.rb"].each { |file| require file }

# Pre 3.0 Mongoid doesn't have this constant defined...
if defined?(Mongoid::VERSION)
  # Mongoid 3.0.3
  Mongoid.load!(File.dirname(__FILE__) + "/config/mongoid.yml", :test)
else
  # Mongoid 2.4.1
  # Didn't use Mongoid.load! here since 2.4.1 doesn't allow passing in an environment to use.
  Mongoid.database = Mongo::Connection.new('localhost','27017').db('changeling_test')
end

$original_sunspot_session = Sunspot.session

RSpec.configure do |config|
  config.mock_with :rspec
  config.include SunspotMatchers

  config.before(:suite) do
    DatabaseCleaner[:mongoid].strategy = :truncation
  end

  config.before(:each) do
    DatabaseCleaner.start
    Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
  end

  config.before :each, :solr => true do
    Sunspot.session = $original_sunspot_session
    Sunspot.remove_all!
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

def models
  @models = {
    BlogPost => {
      :options => {
        :title => "Changeling",
        :content => "Something about Changeling",
        :public => false
      },
      :changes => {
        "public" => [false, true],
        "content" => ["Something about Changeling", "Content about Changeling"]
      }
    },

    BlogPostNoTimestamp => {
      :options => {
        :title => "Changeling",
        :content => "Something about Changeling",
        :public => false
      },
      :changes => {
        "public" => [false, true],
        "content" => ["Something about Changeling", "Content about Changeling"]
      }
    }
  }
end
