module AwesomeSpawn
  class CommandResultError < StandardError
    def self.default_message(command, exit_status)
      "#{command} exit code: #{exit_status}"
    end

    # @return [CommandResult] The command that caused the error
    attr_reader :result

    def initialize(message, result)
      message += " error was: #{result.error}" if !result.nil? && !result.error.empty?
      super(message)
      @result = result
    end
  end
end
