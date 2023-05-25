require 'awesome_spawn'

module AwesomeSpawn
  module SpecHelper
    # Disable spawning for specs
    #
    # @example Disable spawning for all specs
    #   RSpec.configure do |config|
    #     AwesomeSpawn::SpecHelper.disable_spawning(config)
    #   end
    #
    # @example Disable spawning for specs in a specific path
    #   RSpec.configure do |config|
    #     AwesomeSpawn::SpecHelper.disable_spawning(config, file_path: "spec/models")
    #   end
    #
    # @param config [RSpec::Core::Configuration] RSpec configuration
    # @param file_path [String] Restrict the disabling to a specific set of specs in the given path
    def self.disable_spawning(config, file_path: nil)
      if file_path
        config.define_derived_metadata(:file_path => file_path) do |metadata|
          metadata[:uses_awesome_spawn] = true
        end
        config.include AwesomeSpawn::SpecHelper, :uses_awesome_spawn => true
        config.before(:each, :uses_awesome_spawn) { disable_spawning }
      else
        config.include AwesomeSpawn::SpecHelper
        config.before { disable_spawning }
      end
      config
    end

    def disable_spawning
      allow(Open3).to receive(:capture3)
        .and_raise("Spawning is not permitted in specs.  Please change your spec to use expectations/stubs.")
    end

    def enable_spawning
      allow(Open3).to receive(:capture3).and_call_original
    end

    def stub_good_run(command, options = {})
      stub_run(:good, :run, command, options)
    end

    def stub_bad_run(command, options = {})
      stub_run(:bad, :run, command, options)
    end

    def stub_good_run!(command, options = {})
      stub_run(:good, :run!, command, options)
    end

    def stub_bad_run!(command, options = {})
      stub_run(:bad, :run!, command, options)
    end

    private

    def stub_run(mode, method, command, options)
      options = options.dup
      output = options.delete(:output) || ""
      error  = options.delete(:error)  || (mode == :bad ? "Failure" : "")
      pid    = options.delete(:pid)    || ""
      exit_status = options.delete(:exit_status) || (mode == :bad ? 1 : 0)

      command_line = AwesomeSpawn.build_command_line(command, options[:params])

      args = [command, options]

      result = CommandResult.new(command_line, output, error, pid, exit_status)
      if method == :run! && mode == :bad
        error_message = CommandResultError.default_message(command, exit_status)
        error = CommandResultError.new(error_message, result)
        expect(AwesomeSpawn).to receive(method).with(*args).and_raise(error)
      else
        expect(AwesomeSpawn).to receive(method).with(*args).and_return(result)
      end
      result
    end
  end
end
