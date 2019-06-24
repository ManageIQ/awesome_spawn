require 'spec_helper'

describe AwesomeSpawn::SpecHelper do
  include AwesomeSpawn::SpecHelper

  let(:command) { "echo" }
  let(:options) { {:params => {:n => nil, nil => "$STUFF"}, :env => {"STUFF" => "things"}} }

  describe "#stub_good_run" do
    it "returns a 0 exit status" do
      stub_good_run(command, options)
      result = AwesomeSpawn.run(command, options)
      expect(result.exit_status).to eq(0)
    end
  end

  describe "#stub_bad_run" do
    it "returns a non-zero exit status" do
      stub_bad_run(command, options)
      result = AwesomeSpawn.run(command, options)
      expect(result.exit_status).to_not eq(0)
    end
  end

  describe "#stub_good_run!" do
    it "returns a 0 exit status" do
      stub_good_run!(command, options)
      result = AwesomeSpawn.run!(command, options)
      expect(result.exit_status).to eq(0)
    end
  end

  describe "#stub_bad_run!" do
    it "raises a CommandResultError" do
      stub_bad_run!(command, options)
      expect { AwesomeSpawn.run!(command, options) }.to raise_error(AwesomeSpawn::CommandResultError)
    end
  end
end
