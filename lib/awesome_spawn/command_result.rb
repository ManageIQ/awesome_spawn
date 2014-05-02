module AwesomeSpawn
  class CommandResult
    attr_reader :command_line, :output, :error, :exit_status

    def initialize(command_line, output, error, exit_status)
      @command_line = command_line
      @output       = output
      @error        = error
      @exit_status  = exit_status
    end

    def success?
      exit_status == 0
    end

    def failure?
      exit_status != 0
    end

    def inspect
      "#{to_s.chop} @exit_status=#{@exit_status}>"
    end
  end
end
