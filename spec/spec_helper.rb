if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'awesome_spawn/spec_helper'

RSpec.configure do |config|
  AwesomeSpawn::SpecHelper.disable_spawning(config)
end

require 'awesome_spawn'
