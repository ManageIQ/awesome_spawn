module Open3
  # This is a combination of the functionality of Open3.capture3 and
  # Open3.pipeline_r
  #
  # Open3.pipeline_r doesn't support capturing stderr, so this method takes the
  # setup code found in `Open3#popen3`, and the block from `Open3#capture3`,
  # and combines them into a single method.
  #
  # Should have the same interface as `Open3.capture3`, but supports passing in
  # pipes.
  def pipe_capture3(env, cmds, stdin_data: '', binmode: false, **opts)
    # Begin excerpt from Open3.popen3
    in_r, in_w = IO.pipe
    opts[:in] = in_r
    in_w.sync = true

    out_r, out_w = IO.pipe
    opts[:out] = out_w

    err_r, err_w = IO.pipe
    opts[:err] = err_w
    # End excerpt from Open3.popen3

    # Inject global ENV to all commands
    commands   = cmds.map { |cmd| Array(cmd).unshift(env) }
    child_ios  = [in_r, out_w, err_w]
    parent_ios = [in_w, out_r, err_r]

    pipeline_run(commands, opts, child_ios, parent_ios) do |*result|
      # Mostly the same as the block content in Open3#capture3, except that
      # pipeline_run returns an array of Processes that have been piped to, and
      # we just want the status of the last one.
      pipe_in, pipe_out, pipe_err, child_pids = result
      # Begin block excerpt from Open3#capture3
      if binmode
        pipe_in.binmode
        pipe_out.binmode
        pipe_err.binmode
      end
      out_reader = Thread.new { pipe_out.read }
      err_reader = Thread.new { pipe_err.read }
      begin
        pipe_in.write(stdin_data)
      rescue Errno::EPIPE # rubocop:disable Lint/HandleExceptions (original code)
      end
      pipe_in.close
      # End block excerpt from Open3#capture3
      [out_reader.value, err_reader.value, child_pids.last.value]
    end
  end
  module_function :pipe_capture3
end
