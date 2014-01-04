module AwesomeSpawn
  class CommandResultError < StandardError
    # @return [CommandResult] The command that caused the error
    attr_reader :result

    def initialize(message, result)
      super(message)
      @result = result
    end
  end
end
