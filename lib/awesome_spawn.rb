require "awesome_spawn/version"
require "awesome_spawn/command_line_builder"
require "awesome_spawn/command_result"
require "awesome_spawn/command_result_error"
require "awesome_spawn/no_such_file_error"
require "awesome_spawn/null_logger"

require "open3"
require "core_ext/open3"

module AwesomeSpawn
  extend self

  attr_writer :logger

  def logger
    @logger ||= NullLogger.new
  end

  # Execute `command` synchronously via Kernel.spawn and gather the output
  #   stream, error stream, and exit status in a {CommandResult}.
  #
  # @example With normal output
  #   result = AwesomeSpawn.run('echo Hi')
  #   # => #<AwesomeSpawn::CommandResult:0x007f9d1d197320 @exit_status=0>
  #   result.output       # => "Hi\n"
  #   result.error        # => ""
  #   result.exit_status  # => 0
  #
  # @example With error output as well
  #   result = AwesomeSpawn.run('echo Hi; echo "Hi2" 1>&2')
  #   # => <AwesomeSpawn::CommandResult:0x007ff64b98d930 @exit_status=0>
  #   result.output       # => "Hi\n"
  #   result.error        # => "Hi2\n"
  #   result.exit_status  # => 0
  #
  # @example With exit status that is not 0
  #   result = AwesomeSpawn.run('false')
  #   #<AwesomeSpawn::CommandResult:0x007ff64b971410 @exit_status=1>
  #   result.exit_status  # => 1
  #
  # @example With parameters sanitized
  #   result = AwesomeSpawn.run('echo', :params => {:out => "; rm /some/file"})
  #   # => #<AwesomeSpawn::CommandResult:0x007ff64baa6650 @exit_status=0>
  #   result.command_line
  #   # => "echo --out \\;\\ rm\\ /some/file"
  #
  # @example With data to be passed on stdin
  #   result = AwesomeSpawn.run('cat', :in_data => "line1\nline2")
  #   => #<AwesomeSpawn::CommandResult:0x007fff05b0ab10 @exit_status=0>
  #   result.output
  #   => "line1\nline2"
  #
  # @example With environment variables passed in
  #   result = AwesomeSpawn.run('echo ABC=${ABC}', :env => {"ABC" => "abcde"})
  #   => #<AwesomeSpawn::CommandResult:0x007f9421a35590 @exit_status=0>
  #   result.output
  #   => "ABC=abcde\n"
  #
  # @example With pipes
  #   result = AwesomeSpawn.run("true", "echo 'hi'; echo 'err' 1>&2;")
  #   => #<AwesomeSpawn::CommandResult:0x007f9421a35590 @exit_status=0>
  #   result.output       #=> "hi\n"
  #   result.error        #=> "err\n"
  #   result.exit_status  #=> 0
  #   result.command_line #=> ["true", "echo 'hi'; echo 'err' 1>&2;"]
  #
  #   hash_pipe = [
  #     "echo $TXT",
  #     "cat",
  #     ["wc", {:params => {:c => nil}],
  #     ["tr", {:params => [:d, " "]}]
  #   ]
  #   result2 = AwesomeSpawn.run(hash_pipe, :env => {:TXT => "hello world"})
  #   => #<AwesomeSpawn::CommandResult:0x007f9421a35590 @exit_status=0>
  #   result2.output       #=> "12\n"
  #   result2.err          #=> ""
  #   result2.exit_status  #=> 0
  #   result2.command_line #=> ["echo $TXT", "cat", "wc -c", "tr - \\\"\\ \\\""]
  #
  # @param [String] command The command to run
  # @param [Hash] options The options for running the command.  Also accepts any
  #   option that can be passed to Kernel.spawn, except `:in`, `:out` and `:err`.
  # @option options [Hash,Array] :params The command line parameters. See
  #   {#build_command_line} for how to specify params.
  # @option options [String] :in_data Data to be passed on stdin.
  # @option options [Hash<String,String>] :env Additional environment variables for sub process
  #
  # @raise [NoSuchFileError] if the `command` is not found
  # @return [CommandResult] the output stream, error stream, and exit status
  # @see http://ruby-doc.org/core/Kernel.html#method-i-spawn Kernel.spawn
  def run(*opts)
    command, options = normalize_run_opts(*opts)
    env, command_line, options = parse_command_options(command, options)

    if (in_data = options.delete(:in_data))
      options[:stdin_data] = in_data
    end

    output, error, status = launch(env, command_line, options)
  rescue Errno::ENOENT => err
    raise NoSuchFileError.new(err.message) if NoSuchFileError.detected?(err.message)
    raise
  else
    CommandResult.new(command_line, output, error, status)
  end

  # Same as {#run}, additionally raising a {CommandResultError} if the exit
  #   status is not 0.
  #
  # @example With exit status that is not 0
  #   error = AwesomeSpawn.run!('false') rescue $!
  #   # => #<AwesomeSpawn::CommandResultError: false exit code: 1>
  #   error.message # => false exit code: 1
  #   error.result  # => #<AwesomeSpawn::CommandResult:0x007ff64ba08018 @exit_status=1>
  #
  # @raise [CommandResultError] if the exit status is not 0.
  # @return (see #run)
  def run!(*opts)
    command_result = run(*opts)

    if command_result.failure?
      command = command_result.command_line
      message = CommandResultError.default_message(command, command_result.exit_status)
      logger.error("AwesomeSpawn: #{message}")
      logger.error("AwesomeSpawn: #{command_result.error}")
      raise CommandResultError.new(message, command_result)
    end

    command_result
  end

  # (see CommandLineBuilder#build)
  def build_command_line(command, params = nil)
    CommandLineBuilder.new.build(command, params)
  end

  private

  def launch(env, command, spawn_options)
    if command.kind_of?(Array)
      output, error, status = Open3.pipe_capture3(env, command, spawn_options)
    else
      output, error, status = Open3.capture3(env, command, spawn_options)
    end
    return output, error, status && status.exitstatus
  end

  def normalize_run_opts(*opts)
    commands, options = if opts.last.kind_of?(Hash)
                          [opts[0..-2], opts.last]
                        else
                          [opts, {}]
                        end

    if flatten_command_array?(commands)
      commands = commands.flatten(1)
    end

    bad_keys = (options.keys.flatten & [:in, :out, :err]).map { |k| ":#{k}" }
    raise ArgumentError, "options cannot contain #{bad_keys.join(", ")}" if bad_keys.any?

    [Array(commands), options]
  end

  # Flatten the commands array (added too many levels of arrays) if the
  # following are met:
  #
  #  * The `commands` array is all of type Array AND
  #    - It is a single element array (meaning splat arguments are fine here)
  #    - The elements in the array are all NOT all command tuples
  #
  # So we should flatten:
  #
  #   - [["cmd1", "cmd2", "cmd3"]]
  #   - [["cmd1", ["cmd2", {:params => {}]]]
  #
  # So we should NOT flatten:
  #
  #   - ["cmd1", "cmd2", "cmd3"]
  #   - ["cmd1", ["cmd2", {:params => {}]]
  #   - [["cmd1", {:params => {}], ["cmd2", {:params => {}]]
  def flatten_command_array?(commands)
    return false unless commands.all? { |cmd| cmd.kind_of?(Array) }
    return true  if commands.length == 1
    commands.none? do |cmd|
      cmd.first.kind_of?(String) &&
        (cmd[1].nil? || cmd[1].kind_of?(Hash))
    end
  end

  def parse_command_options(commands, options)
    options = options.dup
    params  = options.delete(:params)
    env = options.delete(:env) || {}

    cmds = if commands.length == 1
             build_command_line(commands.first, params)
           else
             commands.map do |(cmd, args)|
               build_command_line(cmd, (args || {})[:params])
             end
           end

    [env, cmds, options]
  end
end
