require "awesome_spawn/version"
require "awesome_spawn/command_result"
require "awesome_spawn/command_result_error"
require "awesome_spawn/no_such_file_error"

require "shellwords"

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
  #   result = AwesomeSpawn.run('echo', :params => {"--out" => "; rm /some/file"})
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

    output        = ""
    error         = ""
    status        = nil
    command_line  = build_command_line(command, params)

    begin
      output, error = launch(command_line, in_data, options)
      status = exitstatus
    ensure
      output ||= ""
      error  ||= ""
      self.exitstatus = nil
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
  #   prevent command line injection.
  #
  #   - `{"--key" => "value"}`         generates `--key value`
  #   - `{"--key=" => "value"}`        generates `--key=value`
  #   - `{"--key" => nil}`             generates `--key`
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
      v = case v
          when Array;    v.collect {|i| i.to_s.shellescape}
          when NilClass; v
          else           v.to_s.shellescape
          end
      [k, v]
    end
  end

  def assemble_params(sanitized_params)
    sanitized_params.collect do |pair|
      pair_joiner = pair.first.to_s.end_with?("=") ? "" : " "
      pair.flatten.compact.join(pair_joiner)
    end.join(" ")
  end

  # IO pipes have a maximum size of 64k before blocking,
  # so we need to read and write synchronously.
  # http://stackoverflow.com/questions/13829830/ruby-process-spawn-stdout-pipe-buffer-size-limit/13846146#13846146
  THREAD_SYNC_KEY = "#{self.name}-exitstatus"

  def launch(command, in_data, spawn_options = {})
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe
    in_r,  in_w  = IO.pipe if in_data

    spawn_options[:out] = out_w
    spawn_options[:err] = err_w
    spawn_options[:in]  = in_r if in_data

    pid = Kernel.spawn(command, spawn_options)

    write_to_input(in_w, in_data) if in_data
    wait_for_process(pid, out_w, err_w, in_r)
    wait_for_pipes(out_r, err_r)
  end

  def write_to_input(in_w, in_data)
    in_w.write(in_data)
    in_w.close
  end

  def wait_for_process(pid, out_w, err_w, in_r)
    self.exitstatus = :not_done
    Thread.new(Thread.current) do |parent_thread|
      _, status = Process.wait2(pid)
      out_w.close
      err_w.close
      in_r.close if in_r
      parent_thread[THREAD_SYNC_KEY] = status.exitstatus
    end
  end

  def wait_for_pipes(out_r, err_r)
    out = out_r.read
    err = err_r.read
    sleep(0.1) while exitstatus == :not_done
    return out, err
  end

  def exitstatus
    Thread.current[THREAD_SYNC_KEY]
  end

  def exitstatus=(value)
    Thread.current[THREAD_SYNC_KEY] = value
  end
end
