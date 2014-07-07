require 'spec_helper'
require 'pathname' # For Pathname specific specs

describe AwesomeSpawn do
  subject { described_class }

  let(:params) do
    {
      "--user"     => "bob",
      "--pass"     => "P@$sw0^& |<>/-+*d%",
      "--db"       => nil,
      "--desc="    => "Some Description",
      :symkey      => nil,
      :symkey_dash => nil,
      nil          => ["pkg1", "some pkg"]
    }
  end

  let (:modified_params) do
    params.to_a + [123, 456].collect {|pool| ["--pool", pool]}
  end

  shared_examples_for "run" do
    context "options" do
      it ":params won't be modified" do
        orig_params = params.dup
        subject.stub(:launch => ["", "", 0])
        subject.send(run_method, "true", :params => params)
        expect(orig_params).to eq(params)
      end

      it ":in_data cannot be passed with :in" do
        expect { subject.send(run_method, "true", :in_data => "XXXXX", :in => "/dev/null") } .to raise_error(ArgumentError)
      end

      it ":out is not supported" do
        expect { subject.send(run_method, "true", :out => "/dev/null") }.to raise_error(ArgumentError)
      end

      it ":err is not supported" do
        expect { subject.send(run_method, "true", :err => "/dev/null") }.to raise_error(ArgumentError)
      end
    end

    context "with real execution" do
      before do
        # Re-enable actual spawning just for these specs.
        enable_spawning
      end

      it "command ok exit ok" do
        expect(subject.send(run_method, "true")).to be_kind_of AwesomeSpawn::CommandResult
      end

      it "command ok exit bad" do
        if run_method == "run!"
          error = nil

          # raise_error with do/end block notation is broken in rspec-expectations 2.14.x
          # and has been fixed in master but not yet released.
          # See: https://github.com/rspec/rspec-expectations/commit/b0df827f4c12870aa4df2f20a817a8b01721a6af
          expect { subject.send(run_method, "false") }.to raise_error {|e| error = e }
          expect(error).to be_kind_of AwesomeSpawn::CommandResultError
          expect(error.result).to be_kind_of AwesomeSpawn::CommandResult
        else
          expect { subject.send(run_method, "false") }.to_not raise_error
        end
      end

      it "command bad" do
        expect { subject.send(run_method, "XXXXX --user=bob") }.to raise_error(Errno::ENOENT, "No such file or directory - XXXXX")
      end

      context "with option" do
        it ":chdir" do
          result = subject.send(run_method, "pwd", :chdir => "..")
          expect(result.exit_status).to  eq(0)
          expect(result.output.chomp).to eq(File.expand_path("..", Dir.pwd))
        end

        it ":in_data" do
          result = subject.send(run_method, "cat", :in_data => "line1\nline2")
          expect(result.exit_status).to eq(0)
          expect(result.output).to      eq("line1\nline2")
        end
      end

      context "#exit_status" do
        it "command ok exit ok" do
          expect(subject.send(run_method, "true").exit_status).to eq(0)
        end

        it "command ok exit bad" do
          expect(subject.send(run_method, "false").exit_status).to eq(1) if run_method == "run"
        end
      end

      context "#output" do
        it "command ok exit ok" do
          expect(subject.send(run_method, "echo \"Hello World\"").output).to eq("Hello World\n")
        end

        it "command ok exit bad" do
          expect(subject.send(run_method, "echo 'bad' && false").output).to eq("bad\n") if run_method == "run"
        end
      end

      context "#error" do
        it "command ok exit ok" do
          expect(subject.send(run_method, "echo \"Hello World\" >&2").error).to eq("Hello World\n")
        end

        it "command ok exit bad" do
          expect(subject.send(run_method, "echo 'bad' >&2 && false").error).to eq("bad\n") if run_method == "run"
        end
      end
    end
  end

  context ".run" do
    include_examples "run" do
      let(:run_method) {"run"}
    end
  end

  context ".run!" do
    include_examples "run" do
      let(:run_method) {"run!"}
    end
  end

  context ".build_command_line" do
    it "sanitizes crazy params" do
      cl = subject.build_command_line("true", modified_params)
      expect(cl).to eq "true --user bob --pass P@\\$sw0\\^\\&\\ \\|\\<\\>/-\\+\\*d\\% --db --desc=Some\\ Description --symkey --symkey-dash pkg1 some\\ pkg --pool 123 --pool 456"
    end

    it "handles Symbol keys" do
      cl = subject.build_command_line("true", :abc => "def")
      expect(cl).to eq "true --abc def"
    end

    it "handles Symbol keys with tailing '='" do
      cl = subject.build_command_line("true", :abc= => "def")
      expect(cl).to eq "true --abc=def"
    end

    it "handles Symbol keys with underscore" do
      cl = subject.build_command_line("true", :abc_def => "ghi")
      expect(cl).to eq "true --abc-def ghi"
    end

    it "handles Symbol keys with underscore and tailing '='" do
      cl = subject.build_command_line("true", :abc_def= => "ghi")
      expect(cl).to eq "true --abc-def=ghi"
    end

    it "sanitizes Fixnum array param value" do
      cl = subject.build_command_line("true", nil => [1])
      expect(cl).to eq "true 1"
    end

    it "sanitizes Pathname param value" do
      cl = subject.build_command_line("true", nil => [Pathname.new("/usr/bin/ruby")])
      expect(cl).to eq "true /usr/bin/ruby"
    end

    it "sanitizes Pathname param key" do
      cl = subject.build_command_line("true", Pathname.new("/usr/bin/ruby") => nil)
      expect(cl).to eq "true /usr/bin/ruby"
    end

    it "with params as empty Hash" do
      cl = subject.build_command_line("true", {})
      expect(cl).to eq "true"
    end

    it "with params as nil" do
      cl = subject.build_command_line("true", nil)
      expect(cl).to eq "true"
    end

    it "without params" do
      cl = subject.build_command_line("true")
      expect(cl).to eq "true"
    end

    it "with Pathname command" do
      cl = subject.build_command_line(Pathname.new("/usr/bin/ruby"))
      expect(cl).to eq "/usr/bin/ruby"
    end

    it "with Pathname command and params" do
      cl = subject.build_command_line(Pathname.new("/usr/bin/ruby"), "-v" => nil)
      expect(cl).to eq "/usr/bin/ruby -v"
    end
  end
end
