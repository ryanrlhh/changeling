require 'rubygems'
require 'sunspot'
require "changeling/version"

module Changeling
  autoload :Trackling, 'changeling/trackling'
  autoload :Probeling, 'changeling/probeling'
  autoload :Sunspotable, 'changeling/sunspotable'

  module Models
    autoload :Logling, 'changeling/models/logling'
  end
end
