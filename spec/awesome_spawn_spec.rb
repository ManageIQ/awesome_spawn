require 'spec_helper'
require 'pathname' # For Pathname specific specs

describe AwesomeSpawn do
  subject { described_class }

  shared_examples_for "parses" do
    it "supports no options" do
      allow(subject).to receive(:launch).with({}, "true", {}).and_return(["", "", 0])
      subject.send(run_method, "true")
    end

    it "supports option :params and :env" do
      allow(subject).to receive(:launch).with({"VAR" => "x"}, "true --user bob", {}).and_return(["", "", 0])
      subject.send(run_method, "true", :params => {:user => "bob"}, :env => {"VAR" => "x"})
    end

    it "supports pipes with :params" do
      cmds = [
        "true",
        ["true", :params => { :arg1 => "one", :no_arg2 => nil }]
      ]
      expected_cmd = ["true", "true --arg1 one --no-arg2"]
      allow(subject).to receive(:launch).with({}, expected_cmd, {}).and_return(["", "", 0])
      subject.send(run_method, *cmds)
    end

    it "supports pipes with env" do
      opts = { :env => { :FOO => "foo", :BAR => "bar" } }
      cmds = [
        "true",
        ["true", :params => { :arg1 => "one", :no_arg2 => nil }]
      ]

      in_r,  in_w  = IO.pipe
      out_r, out_w = IO.pipe
      err_r, err_w = IO.pipe
      expect(IO).to receive(:pipe).and_return([in_r, in_w], [out_r, out_w], [err_r, err_w])

      expected_pipeline_run_args = [
        [[opts[:env], "true"], [opts[:env], "true --arg1 one --no-arg2"]],
        {:in => in_r, :out => out_w, :err => err_w},
        [in_r, out_w, err_w],
        [in_w, out_r, err_r]
      ]
      allow(Open3).to receive(:pipeline_run).with(*expected_pipeline_run_args).and_return(["", "", double(:exitstatus => 0)])

      subject.send(run_method, *cmds, opts)
    end

    it "supports multi-level pipes with mixed args and single strings" do
      cmds = [
        "echo hello world",
        "cat",
        ["wc", { :params => { :c => nil} }],
        ["tr", { :params => { :d => '" "'} }]
      ]
      expected_cmd = ['echo hello world', 'cat', 'wc -c', 'tr -d \\"\\ \\"']
      allow(subject).to receive(:launch).with({}, expected_cmd, {}).and_return(["", "", 0])
      subject.send(run_method, *cmds)
    end

    it "wont modify passed in options" do
      options      = {:params => {:user => "bob"}}
      orig_options = options.dup
      allow(subject).to receive(:launch).with({}, "true --user bob", {}).and_return(["", "", 0])
      subject.send(run_method, "true", options)
      expect(orig_options).to eq(options)
    end

    it "wont modify passed in options[:params]" do
      params      = {:user => "bob"}
      orig_params = params.dup
      allow(subject).to receive(:launch).with({}, "true --user bob", {}).and_return(["", "", 0])
      subject.send(run_method, "true", :params => params)
      expect(orig_params).to eq(params)
    end

    it "warns about option :in" do
      expect do
        subject.send(run_method, "true", :in => "/dev/null")
      end.to raise_error(ArgumentError, "options cannot contain :in")
    end

    it "warns about option :out" do
      expect do
        subject.send(run_method, "true", :out => "/dev/null")
      end.to raise_error(ArgumentError, "options cannot contain :out")
    end

    it "warns about option :err" do
      expect do
        subject.send(run_method, "true", :err => "/dev/null")
      end.to raise_error(ArgumentError, "options cannot contain :err")
    end

    it "warns about option :err when in an array" do
      expect do
        subject.send(run_method, "true", [:err, :out, 3] => "/dev/null")
      end.to raise_error(ArgumentError, "options cannot contain :err, :out")
    end
  end

  shared_examples_for "executes" do
    before do
      # Re-enable actual spawning just for these specs.
      enable_spawning
    end

    it "runs command" do
      expect(subject.send(run_method, "true")).to be_kind_of AwesomeSpawn::CommandResult
    end

    describe "with pipes" do
      # expected_cmd = "true --arg1 one --no-arg2 | echo 'hello world'; echo 'err' 1>&2"
      let(:cmds) do
        [
          ["true", :params => { :arg1 => "one", :no_arg2 => nil }],
          "echo 'hello world'; echo 'err' 1>&2"
        ]
      end

      before do
        @result = described_class.send(run_method, *cmds)
      end

      it "it returns exit_status of the last cmd piped_to" do
        expect(@result.exit_status).to eq(0)
      end

      it "it captures output" do
        expect(@result.output).to eq("hello world\n")
      end

      it "it captures error" do
        expect(@result.error).to eq("err\n")
      end
    end

    it "detects bad commands" do
      expect do
        subject.send(run_method, "XXXXX --user=bob")
      end.to raise_error(AwesomeSpawn::NoSuchFileError, "No such file or directory - XXXXX")
    end

    describe "parameters" do
      it "changes directory" do
        result = subject.send(run_method, "pwd", :chdir => "..")
        expect(result.exit_status).to  eq(0)
        expect(result.output.chomp).to eq(File.expand_path("..", Dir.pwd))
      end

      it "passes input" do
        result = subject.send(run_method, "cat", :in_data => "line1\nline2")
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("line1\nline2")
      end

      it "sets environment" do
        result = subject.send(run_method, "echo ${ABC}", :env => {"ABC" => "yay!"})
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("yay!\n")
      end
    end

    describe "result" do
      it "contains #command_line" do
        expect(subject.send(run_method, "echo", :params => %w(x)).command_line).to eq("echo x")
      end

      it "contains #exit_status" do
        expect(subject.send(run_method, "true").exit_status).to eq(0)
      end

      it "contains #output" do
        expect(subject.send(run_method, "echo \"Hello World\"").output).to eq("Hello World\n")
      end

      it "contains #output when output redirected to stderr)" do
        expect(subject.send(run_method, "echo \"Hello World\" >&2").output).to eq("")
      end

      it "contains #error when no error" do
        expect(subject.send(run_method, "echo", :params => ["Hello World"]).error).to eq("")
      end

      it "contains #error" do
        expect(subject.send(run_method, "echo \"Hello World\" >&2").error).to eq("Hello World\n")
      end
    end
  end

  shared_examples_for "executes with failures" do
    context "result with a bad command" do
      before do
        # Re-enable actual spawning just for these specs.
        enable_spawning
      end

      it "contains #command_line" do
        expect(subject.send(run_method, "echo x && false").command_line).to eq("echo x && false")
      end

      it "contains #exit_status" do
        expect(subject.send(run_method, "false").exit_status).to eq(1)
      end

      it "contains #output" do
        expect(subject.send(run_method, "echo 'bad' && false").output).to eq("bad\n")
      end

      it "contains #error" do
        expect(subject.send(run_method, "echo 'bad' >&2 && false").error).to eq("bad\n")
      end
    end

    describe "with pipes" do
      # expected_cmd = "true --arg1 one --no-arg2 | echo 'hello world'; echo 'err' 1>&2"
      let(:cmds) do
        [
          ["true", :params => { :arg1 => "one", :no_arg2 => nil }],
          "echo 'bye world'; echo 'err' 1>&2; false"
        ]
      end

      before do
        @result = described_class.send(run_method, cmds)
      end

      it "it returns exit_status of the last cmd piped_to" do
        expect(@result.exit_status).to eq(1)
      end

      it "it captures output" do
        expect(@result.output).to eq("bye world\n")
      end

      it "it captures error" do
        expect(@result.error).to eq("err\n")
      end
    end
  end

  describe ".normalize_run_opts" do
    shared_examples_for "cmd arg variations" do
      let(:opts)             { (Array(@cmds.dup) << passed_options).compact }
      let(:expected_options) { passed_options || {} }

      # normalize_run_opts("true", [OPTIONS])
      # #=> ["true"], {}
      it "returns an array + hash with a single string command" do
        @cmds = "true"
        commands, options = subject.send(:normalize_run_opts, *opts)
        expect(commands).to eq(["true"])
        expect(options).to  eq(expected_options)
      end

      # normalize_run_opts(["true"], [OPTIONS])
      # #=> ["true"], {}
      it "returns an array + hash with a single string array command" do
        @cmds = %w(true)
        commands, options = if passed_options
                              subject.send(:normalize_run_opts, @cmds, passed_options)
                            else
                              subject.send(:normalize_run_opts, @cmds)
                            end
        expect(commands).to eq(["true"])
        expect(options).to  eq(expected_options)
      end

      # normalize_run_opts("true", "false", "true", [OPTIONS])
      # #=> ["true", "false", "true"], {}
      it "returns array + hash with splat array of string commands" do
        @cmds = %w(true false true)
        commands, options = subject.send(:normalize_run_opts, *opts)
        expect(commands).to eq(%w(true false true))
        expect(options).to  eq(expected_options)
      end

      # normalize_run_opts(["true", "false", "true"], [OPTIONS])
      # #=> ["true", "false", "true"], {}
      it "returns array + hash with single arg array of string commands" do
        @cmds = %w(true false true)
        commands, options = if passed_options
                              subject.send(:normalize_run_opts, @cmds, passed_options)
                            else
                              subject.send(:normalize_run_opts, @cmds)
                            end
        expect(commands).to eq(%w(true false true))
        expect(options).to  eq(expected_options)
      end

      # (technically valid, but stupid case)
      #
      # normalize_run_opts([["true", { :params => {} }]], {})
      # #=> [["true", { :params => {} }]], {}
      it "returns array + hash with a string plus params hash" do
        @cmds = [["true", { :params => { :a => nil } }]]
        commands, options = if passed_options
                              subject.send(:normalize_run_opts, @cmds, passed_options)
                            else
                              subject.send(:normalize_run_opts, @cmds)
                            end
        expect(commands).to eq([["true", { :params => { :a => nil } }]])
        expect(options).to  eq(expected_options)
      end

      # normalize_run_opts("false", ["true", {:params => {:a => nil}], "false", [OPTIONS])
      # #=> ["false", ["true", {:params => {:a => nil}], "false"], {}
      it "returns array + hash with a splat array mixed with single strings and tuples" do
        @cmds = ["false", ["true", { :params => { :a => nil } }], "false"]
        commands, options = subject.send(:normalize_run_opts, *opts)
        expect(commands).to eq(["false", ["true", { :params => { :a => nil } }], "false"])
        expect(options).to  eq(expected_options)
      end

      # normalize_run_opts(["false", ["true", {:params => {:a => nil}], "false"], [OPTIONS])
      # #=> ["false", ["true", {:params => {:a => nil}], "false"], {}
      it "returns array + hash with a splat array mixed with single strings and tuples" do
        @cmds = ["false", ["true", { :params => { :a => nil } }], "false"]
        commands, options = if passed_options
                              subject.send(:normalize_run_opts, @cmds, passed_options)
                            else
                              subject.send(:normalize_run_opts, @cmds)
                            end
        expect(commands).to eq(["false", ["true", { :params => { :a => nil } }], "false"])
        expect(options).to  eq(expected_options)
      end

      # normalize_run_opts([["false", { :params => { :a => nil } }], ["true", { :params => [:b, nil] }]], [OPTIONS])
      # #=> [["false", { :params => { :a => nil } }], ["true", { :params => [:b, nil] }]], {}
      it "returns array + hash with a single array of many cmd+params commands" do
        @cmds = [["false", { :params => { :a => nil } }], ["true", { :params => [:b, nil] }]]
        commands, options = if passed_options
                              subject.send(:normalize_run_opts, @cmds, passed_options)
                            else
                              subject.send(:normalize_run_opts, @cmds)
                            end
        expect(commands).to eq(@cmds)
        expect(options).to  eq(expected_options)
      end

      # normalize_run_opts(["false", { :params => { :a => nil } }], ["true", { :params => [:b, nil] }], [OPTIONS])
      # #=> [["false", { :params => { :a => nil } }], ["true", { :params => [:b, nil] }]], {}
      it "returns array + hash with a splat array of many cmd+params commands" do
        @cmds = [["false", { :params => { :a => nil } }], ["true", { :params => [:b, nil] }]]
        commands, options = if passed_options
                              subject.send(:normalize_run_opts, *[@cmds, passed_options])
                            else
                              subject.send(:normalize_run_opts, *@cmds)
                            end
        expect(commands).to eq(@cmds)
        expect(options).to  eq(expected_options)
      end
    end

    context "with options" do
      let(:passed_options) { { :env => {}, :params => {} } }

      include_examples "cmd arg variations"
    end

    context "without options" do
      let(:passed_options) { nil }

      include_examples "cmd arg variations"
    end
  end

  describe ".build_command_line" do
    it "supports no parameters" do
      expect(subject.build_command_line("cmd")).to eq("cmd")
    end

    it "supports single long parameter" do
      expect(subject.build_command_line("cmd", :status => true)).to eq("cmd --status true")
    end

    it "supports multiple long parameters" do
      expect(subject.build_command_line("cmd", :status => true, :fast => false)).to eq("cmd --status true --fast false")
    end
  end

  describe ".run" do
    let(:run_method) { "run" }
    include_examples "parses"
    include_examples "executes"
    include_examples "executes with failures"
  end

  describe ".run!" do
    let(:run_method) { "run!" }
    include_examples "parses"
    include_examples "executes"

    it "raises errors on failure" do
      expect { subject.send(run_method, "false") }.to raise_error do |error|
        expect(error).to be_kind_of AwesomeSpawn::CommandResultError
        expect(error.result).to be_kind_of AwesomeSpawn::CommandResult
      end
    end
  end
end
