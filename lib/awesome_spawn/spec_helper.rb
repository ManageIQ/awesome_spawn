module AwesomeSpawn
  module SpecHelper
    def disable_spawning
      allow(Open3).to receive(:capture3)
        .and_raise("Spawning is not permitted in specs.  Please change your spec to use expectations/stubs.")
    end

    def enable_spawning
      allow(Open3).to receive(:capture3).and_call_original
    end
  end
end
