require 'spec_helper'
require 'pathname' # For Pathname specific specs

describe AwesomeSpawn do
  subject { described_class }
  let(:status) { double("status") }

  shared_examples_for "parses" do
    before do
      allow(status).to receive_messages(:exitstatus => 0, :pid => 3)
    end

    it "supports no options" do
      allow(subject).to receive(:launch).with({}, "true", {}).and_return(["", "", status])
      subject.send(run_method, "true")
    end

    it "supports option :params and :env" do
      allow(subject).to receive(:launch).with({"VAR" => "x"}, "true --user bob", {}).and_return(["", "", status])
      subject.send(run_method, "true", :params => {:user => "bob"}, :env => {"VAR" => "x"})
    end

    it "won't modify passed in options" do
      options      = {:params => {:user => "bob"}}
      orig_options = options.dup
      allow(subject).to receive(:launch).with({}, "true --user bob", {}).and_return(["", "", status])
      subject.send(run_method, "true", options)
      expect(orig_options).to eq(options)
    end

    it "won't modify passed in options[:params]" do
      params      = {:user => "bob"}
      orig_params = params.dup
      allow(subject).to receive(:launch).with({}, "true --user bob", {}).and_return(["", "", status])
      subject.send(run_method, "true", :params => params)
      expect(orig_params).to eq(params)
    end

    it "errors on option :in" do
      expect do
        subject.send(run_method, "true", :in => "/dev/null")
      end.to raise_error(ArgumentError, "options cannot contain :in")
    end

    it "errors on option :out" do
      expect do
        subject.send(run_method, "true", :out => "/dev/null")
      end.to raise_error(ArgumentError, "options cannot contain :out")
    end

    it "errors on option :err" do
      expect do
        subject.send(run_method, "true", :err => "/dev/null")
      end.to raise_error(ArgumentError, "options cannot contain :err")
    end

    it "errors on option :err when in an array" do
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

      it "handles numeric parameters" do
        result = subject.send(run_method, "echo ${ABC}", :params => [5], :env => {"ABC" => "yay!"})
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("yay! 5\n")
      end

      it "handles numeric env variables" do
        result = subject.send(run_method, "echo v=${ABC}", :env => {"ABC" => 5})
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("v=5\n")
      end

      it "handles blank env variables (not checking presence)" do
        result = subject.send(run_method, "echo v=\"'${ABC-none}'\"", :env => {"ABC" => ""})
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("v=''\n")
      end

      it "handles blank env variables (checking presence)" do
        result = subject.send(run_method, "echo v=\"'${ABC:-none}'\"", :env => {"ABC" => ""})
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("v='none'\n")
      end

      it "handles nil env variables (not checking presence)" do
        result = subject.send(run_method, "echo v=\"'${ABC-none}'\"", :env => {"ABC" => nil})
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("v='none'\n")
      end

      it "handles nil env variables (checking presence)" do
        result = subject.send(run_method, "echo v=\"'${ABC:-none}'\"", :env => {"ABC" => nil})
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("v='none'\n")
      end

      it "handles symbolic env keys and values" do
        result = subject.send(run_method, "echo ${ABC}", :env => {:ABC => :yay})
        expect(result.exit_status).to eq(0)
        expect(result.output).to      eq("yay\n")
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

      it "combines output when using :combined_output => true" do
        result = subject.send(run_method, "echo good && echo 'bad' >&2 && false", :combined_output => true)

        expect(result.output).to eq("good\nbad\n")
        expect(result.error).to  eq("")
      end

      it "allows :combined_output to be falsey" do
        result = subject.send(run_method, "echo good && echo 'bad' >&2 && false", :combined_output => false)

        expect(result.output).to eq("good\n")
        expect(result.error).to  eq("bad\n")
      end
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
