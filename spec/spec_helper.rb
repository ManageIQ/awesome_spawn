if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'awesome_spawn/spec_helper'

RSpec.configure do |config|
  include AwesomeSpawn::SpecHelper
  config.before { disable_spawning }
end

require 'awesome_spawn'
