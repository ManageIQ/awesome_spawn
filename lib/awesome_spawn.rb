require "awesome_spawn/version"
require "awesome_spawn/command_result"
require "awesome_spawn/command_result_error"
require "awesome_spawn/no_such_file_error"

require "shellwords"
require "open3"

module AwesomeSpawn
  extend self

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
  # @param [String] command The command to run
  # @param [Hash] options The options for running the command.  Also accepts any
  #   option that can be passed to Kernel.spawn, except `:out` and `:err`.
  # @option options [Hash,Array] :params The command line parameters. See
  #   {#build_command_line} for how to specify params.
  # @option options [String] :in_data Data to be passed on stdin.  If this option
  #   is specified you cannot specify `:in`.
  #
  # @raise [NoSuchFileError] if the `command` is not found
  # @return [CommandResult] the output stream, error stream, and exit status
  # @see http://ruby-doc.org/core/Kernel.html#method-i-spawn Kernel.spawn
  def run(command, options = {})
    raise ArgumentError, "options cannot contain :out" if options.include?(:out)
    raise ArgumentError, "options cannot contain :err" if options.include?(:err)
    raise ArgumentError, "options cannot contain :in if :in_data is specified" if options.include?(:in) && options.include?(:in_data)
    options = options.dup
    params  = options.delete(:params)
    in_data = options.delete(:in_data)

    output, error, status = "", "", nil
    command_line = build_command_line(command, params)

    begin
      output, error, status = launch(command_line, in_data, options)
    ensure
      output ||= ""
      error  ||= ""
    end
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
  def run!(command, options = {})
    command_result = run(command, options)

    if command_result.exit_status != 0
      message = "#{command} exit code: #{command_result.exit_status}"
      raise CommandResultError.new(message, command_result)
    end

    command_result
  end

  # Build the full command line.
  #
  # @param [String] command The command to run
  # @param [Hash,Array] params Optional command line parameters. They can
  #   be passed as a Hash or associative Array. The values are sanitized to
  #   prevent command line injection.  Keys as symbols are prefixed with `--`,
  #   and `_` is replaced with `-`.
  #
  #   - `{:key => "value"}`            generates `--key value`
  #   - `{"--key" => "value"}`         generates `--key value`
  #   - `{:key= => "value"}`           generates `--key=value`
  #   - `{"--key=" => "value"}`        generates `--key=value`
  #   - `{:key_name => "value"}`       generates `--key-name value`
  #   - `{:key => nil}`                generates `--key`
  #   - `{"-f" => ["file1", "file2"]}` generates `-f file1 file2`
  #   - `{nil => ["file1", "file2"]}`  generates `file1 file2`
  #
  # @return [String] The full command line
  def build_command_line(command, params = nil)
    return command.to_s if params.nil? || params.empty?
    "#{command} #{assemble_params(sanitize(params))}"
  end

  private

  def sanitize(params)
    return [] if params.nil? || params.empty?
    params.collect do |k, v|
      [sanitize_key(k), sanitize_value(v)]
    end
  end

  def sanitize_key(key)
    case key
    when Symbol then "--#{key.to_s.tr("_", "-")}"
    else             key
    end
  end

  def sanitize_value(value)
    case value
    when Array    then value.collect { |i| i.to_s.shellescape }
    when NilClass then value
    else               value.to_s.shellescape
    end
  end

  def assemble_params(sanitized_params)
    sanitized_params.collect do |pair|
      pair_joiner = pair.first.to_s.end_with?("=") ? "" : " "
      pair.flatten.compact.join(pair_joiner)
    end.join(" ")
  end

  def launch(command, in_data, spawn_options = {})
    spawn_options = spawn_options.merge(:stdin_data => in_data) if in_data
    output, error, status = Open3.capture3(command, spawn_options)
    status &&= status.exitstatus
    return output, error, status
  end
end
