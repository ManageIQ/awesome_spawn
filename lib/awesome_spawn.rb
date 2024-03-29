require "awesome_spawn/version"
require "awesome_spawn/command_line_builder"
require "awesome_spawn/command_result"
require "awesome_spawn/command_result_error"
require "awesome_spawn/no_such_file_error"
require "awesome_spawn/null_logger"

require "open3"

module AwesomeSpawn
  extend self

  attr_writer :logger

  def logger
    @logger ||= NullLogger.new
  end

  # Execute `command` synchronously via Kernel.spawn and gather the output
  #   stream, error stream, pid, and exit status in a {CommandResult}.
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
  # @param [String] command The command to run
  # @param [Hash] options The options for running the command.  Also accepts any
  #   option that can be passed to Kernel.spawn, except `:in`, `:out` and `:err`.
  # @option options [Hash,Array] :params The command line parameters. See
  #   {#build_command_line} for how to specify params.
  # @option options [String] :in_data Data to be passed on stdin.
  # @option options [Boolean] :combined_output Combine STDOUT/STDERR streams from run command
  # @option options [Hash<String,String>] :env Additional environment variables for sub process
  #
  # @raise [NoSuchFileError] if the `command` is not found
  # @return [CommandResult] the output stream, error stream, and exit status
  # @see http://ruby-doc.org/core/Kernel.html#method-i-spawn Kernel.spawn
  def run(command, options = {})
    bad_keys = (options.keys.flatten & [:in, :out, :err]).map { |k| ":#{k}" }
    raise ArgumentError, "options cannot contain #{bad_keys.join(", ")}" if bad_keys.any?
    env, command_line, options = parse_command_options(command, options)

    if (in_data = options.delete(:in_data))
      options[:stdin_data] = in_data
    end

    output, error, process_status = launch(env, command_line, options)
    status = process_status && process_status.exitstatus
    pid = process_status.pid if process_status

  rescue Errno::ENOENT => err
    raise NoSuchFileError.new(err.message) if NoSuchFileError.detected?(err.message)
    raise
  else
    CommandResult.new(command_line, output, error, pid, status)
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
  def run!(command, options = {})
    command_result = run(command, options)

    if command_result.failure?
      message = CommandResultError.default_message(command, command_result.exit_status)
      error = command_result.error.nil? || command_result.error.empty? ? command_result.output : command_result.error

      logger.error("AwesomeSpawn: #{message}")
      logger.error("AwesomeSpawn: #{error}")
      raise CommandResultError.new(message, command_result)
    end

    command_result
  end

  # Execute `command` in a detached manner
  # The defalt is to spawn a new child process that sends the output to the null device
  # @param [String] command the command to execute
  # @param [Hash{Symbol,Object}] options the Kernel.spawn options
  #   by default the :err, and :out are redirected to the null device.
  #   For windows, default :pgroup_new is true (make a root process of a new process group)
  #   For others,  default :pgroup is true (make a new process group)
  # @returns [Integer] pid of new process
  #
  # @example With normal output
  #   AwesomeSpawn.run_detached('echo "Hi" > /tmp/out')
  #   # => 79901
  #
  # if a user defines :out or :err, it is assumed they will define both
  def run_detached(command, options = {})
    env, command_line, options = parse_command_options(command, options)
    # maybe add support later for this
    raise ArgumentError, "options cannot contain :in_data" if options.include?(:in_data)

    options[[:out, :err]] = [IO::NULL, "w"] unless (options.keys.flatten & [:out, :err]).any?
    if Gem.win_platform?
      options[:new_pgroup]  = true unless options.key?(:new_pgroup)
    else
      options[:pgroup]      = true unless options.key?(:pgroup)
    end

    detach(env, command_line, options)
  end

  # (see CommandLineBuilder#build)
  def build_command_line(command, params = nil)
    CommandLineBuilder.new.build(command, params)
  end

  private

  def launch(env, command, spawn_options)
    capture2e = spawn_options.delete(:combined_output)
    if capture2e
      output, status = Open3.capture2e(env, command, spawn_options)
      error          = ""
    else
      output, error, status = Open3.capture3(env, command, spawn_options)
    end
    return output, error, status
  end

  def parse_command_options(command, options)
    options = options.dup
    params  = options.delete(:params)
    env = (options.delete(:env) || {}).map { |n, v| [n.to_s, v&.to_s] }.to_h

    [env, build_command_line(command, params), options]
  end

  def detach(env, command, options)
    Process.detach(Kernel.spawn(env, command, options)).pid
  end
end
