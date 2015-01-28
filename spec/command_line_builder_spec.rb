require 'spec_helper'

describe AwesomeSpawn::CommandLineBuilder do
  subject { described_class.new }

  context "#build" do
    def assert_params(params, expected_params)
      expect(subject.build("true", params)).to eq "true #{expected_params}".strip
    end

    it "without params" do
      expect(subject.build("true")).to eq "true"
    end

    it "with nil" do
      expect(subject.build("true", nil)).to eq "true"
    end

    it "with empty" do
      expect(subject.build("true", "")).to eq "true"
    end

    it "with empty" do
      expect(subject.build("true", [])).to eq "true"
    end

    it "with Pathname command" do
      actual = subject.build(Pathname.new("/usr/bin/ruby"))
      expect(actual).to eq "/usr/bin/ruby"
    end

    it "with Pathname command and params" do
      actual = subject.build(Pathname.new("/usr/bin/ruby"), "-v" => nil)
      expect(actual).to eq "/usr/bin/ruby -v"
    end

    context "with Hash" do
      it "that is empty" do
        assert_params({}, "")
      end

      it "with normal params" do
        assert_params({"--user" => "bob"}, "--user bob")
      end

      it "with key with tailing '='" do
        assert_params({"--user=" => "bob"}, "--user=bob")
      end

      it "with value requiring sanitization" do
        assert_params({"--pass" => "P@$s w0rd%"}, "--pass P@\\$s\\ w0rd\\%")
      end

      it "with key requiring sanitization" do
        assert_params({"--h&x0r=" => "xxx"}, "--h\\&x0r=xxx")
      end

      it "with key as Symbol" do
        assert_params({:abc => "def"}, "--abc def")
      end

      it "with key as Symbol with tailing '='" do
        assert_params({:abc= => "def"}, "--abc=def")
      end

      it "with key as Symbol with underscore" do
        assert_params({:abc_def => "ghi"}, "--abc-def ghi")
      end

      it "with key as Symbol with underscore and tailing '='" do
        assert_params({:abc_def= => "ghi"}, "--abc-def=ghi")
      end

      it "with key as nil" do
        assert_params({nil => "def"}, "def")
      end

      it "with value as nil" do
        assert_params({"--abc" => nil}, "--abc")
      end

      it "with key and value nil" do
        assert_params({nil => nil}, "")
      end

      it "with key of '--'" do
        assert_params({"--" => nil}, "--")
      end

      it "with value as Symbol" do
        assert_params({"--abc" => :def}, "--abc def")
      end

      it "with value as Array" do
        assert_params({"--abc" => ["def", "ghi"]}, "--abc def ghi")
      end

      it "with value as Fixnum" do
        assert_params({"--abc" => 1}, "--abc 1")
      end

      it "with value as Fixnum Array" do
        assert_params({"--abc" => [1, 2]}, "--abc 1 2")
      end

      it "with value as Range" do
        assert_params({"--abc" => (1..4)}, "--abc 1 2 3 4")
      end

      it "with value as Pathname" do
        assert_params({"--abc" => Pathname.new("/usr/bin/ruby")}, "--abc /usr/bin/ruby")
      end
    end

    context "with associative Array" do
      it "that is empty" do
        assert_params([], "")
      end

      it "that is nested empty" do
        assert_params([[]], "")
      end

      it "with normal params" do
        assert_params([["--user", "bob"]], "--user bob")
      end

      it "with key with tailing '='" do
        assert_params([["--user=", "bob"]], "--user=bob")
      end

      it "with value requiring sanitization" do
        assert_params([["--pass", "P@$s w0rd%"]], "--pass P@\\$s\\ w0rd\\%")
      end

      it "with key requiring sanitization" do
        assert_params([["--h&x0r=", "xxx"]], "--h\\&x0r=xxx")
      end

      it "with key as Symbol" do
        assert_params([[:abc, "def"]], "--abc def")
      end

      it "with key as Symbol with tailing '='" do
        assert_params([[:abc=, "def"]], "--abc=def")
      end

      it "with key as Symbol with underscore" do
        assert_params([[:abc_def, "ghi"]], "--abc-def ghi")
      end

      it "with key as Symbol with underscore and tailing '='" do
        assert_params([[:abc_def=, "ghi"]], "--abc-def=ghi")
      end

      it "with key as nil" do
        assert_params([[nil, "def"]], "def")
      end

      it "with value as nil" do
        assert_params([["--abc", nil]], "--abc")
      end

      it "with key and value nil" do
        assert_params([[nil, nil]], "")
      end

      it "with key as nil and multiple values" do
        assert_params([[nil, "def", "ghi"]], "def ghi")
      end

      it "with key of '--'" do
        assert_params([["--", nil]], "--")
      end

      it "with key alone" do
        assert_params([["--abc"]], "--abc")
      end

      it "with key as Symbol alone" do
        assert_params([[:abc]], "--abc")
      end

      it "with key as a bareword" do
        assert_params(["--abc"], "--abc")
      end

      it "with key as bareword Symbol" do
        assert_params([:abc], "--abc")
      end

      it "with value as a bareword" do
        assert_params(["abc"], "abc")
      end

      it "with entry as a nested Hash" do
        assert_params([{:abc_def= => "ghi"}], "--abc-def=ghi")
      end

      it "with value as Symbol" do
        assert_params([["--abc" => :def]], "--abc def")
      end

      it "with value as Array" do
        assert_params([["--abc", ["def", "ghi"]]], "--abc def ghi")
      end

      it "with value as Array and extra nils" do
        assert_params([["--abc", [nil, "def", nil, "ghi", nil]]], "--abc def ghi")
      end

      it "with value as flattened Array" do
        assert_params([["--abc", "def", "ghi"]], "--abc def ghi")
      end

      it "with value as Fixnum" do
        assert_params([["--abc", 1]], "--abc 1")
      end

      it "with value as Fixnum Array" do
        assert_params([["--abc", [1, 2]]], "--abc 1 2")
      end

      it "with value as Range" do
        assert_params([["--abc", (1..4)]], "--abc 1 2 3 4")
      end

      it "with value as Pathname" do
        assert_params([["--abc", Pathname.new("/usr/bin/ruby")]], "--abc /usr/bin/ruby")
      end

      it "with duplicate keys" do
        assert_params([["--abc", 1], ["--abc", 2]], "--abc 1 --abc 2")
      end
    end

    context "with multiple params" do # real-world cases
      let(:expected) { "log feature -E --oneline --grep abc" }

      it "as full Hash" do
        params = {"log" => nil, "feature" => nil, "-E" => nil, :oneline => nil, "--grep" => "abc"}
        assert_params(params, expected)
      end

      it "as grouped Hash" do
        params = {nil => ["log", "feature"], "-E" => nil, :oneline => nil, :grep => "abc"}
        assert_params(params, expected)
      end

      it "as associative Array" do
        params = [[nil, "log", "feature"], ["-E", nil], [:oneline, nil], [:grep, "abc"]]
        assert_params(params, expected)
      end

      it "as associative Array without nil values" do
        params = [["log", "feature"], ["-E"], [:oneline], [:grep, "abc"]]
        assert_params(params, expected)
      end

      it "as mixed Array with barewords" do
        params = ["log", "feature", "-E", :oneline, [:grep, "abc"]]
        assert_params(params, expected)
      end

      it "as mixed Array" do
        params = ["log", "feature", "-E", :oneline, :grep, "abc"]
        assert_params(params, expected)
      end

      it "as mixed Array with nested Hashes" do
        params = ["log", "feature", "-E", :oneline, {:grep => "abc"}]
        assert_params(params, expected)
      end
    end
  end
end
