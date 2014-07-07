require 'spec_helper'

describe AwesomeSpawn::CommandLineBuilder do
  subject { described_class.new }

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

  context "#build" do
    it "sanitizes crazy params" do
      cl = subject.build("true", modified_params)
      expect(cl).to eq "true --user bob --pass P@\\$sw0\\^\\&\\ \\|\\<\\>/-\\+\\*d\\% --db --desc=Some\\ Description --symkey --symkey-dash pkg1 some\\ pkg --pool 123 --pool 456"
    end

    it "handles Symbol keys" do
      cl = subject.build("true", :abc => "def")
      expect(cl).to eq "true --abc def"
    end

    it "handles Symbol keys with tailing '='" do
      cl = subject.build("true", :abc= => "def")
      expect(cl).to eq "true --abc=def"
    end

    it "handles Symbol keys with underscore" do
      cl = subject.build("true", :abc_def => "ghi")
      expect(cl).to eq "true --abc-def ghi"
    end

    it "handles Symbol keys with underscore and tailing '='" do
      cl = subject.build("true", :abc_def= => "ghi")
      expect(cl).to eq "true --abc-def=ghi"
    end

    it "sanitizes Fixnum array param value" do
      cl = subject.build("true", nil => [1])
      expect(cl).to eq "true 1"
    end

    it "sanitizes Pathname param value" do
      cl = subject.build("true", nil => [Pathname.new("/usr/bin/ruby")])
      expect(cl).to eq "true /usr/bin/ruby"
    end

    it "sanitizes Pathname param key" do
      cl = subject.build("true", Pathname.new("/usr/bin/ruby") => nil)
      expect(cl).to eq "true /usr/bin/ruby"
    end

    it "with params as empty Hash" do
      cl = subject.build("true", {})
      expect(cl).to eq "true"
    end

    it "with params as nil" do
      cl = subject.build("true", nil)
      expect(cl).to eq "true"
    end

    it "without params" do
      cl = subject.build("true")
      expect(cl).to eq "true"
    end

    it "with Pathname command" do
      cl = subject.build(Pathname.new("/usr/bin/ruby"))
      expect(cl).to eq "/usr/bin/ruby"
    end

    it "with Pathname command and params" do
      cl = subject.build(Pathname.new("/usr/bin/ruby"), "-v" => nil)
      expect(cl).to eq "/usr/bin/ruby -v"
    end
  end
end
