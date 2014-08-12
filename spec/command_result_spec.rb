require 'spec_helper'

describe AwesomeSpawn::CommandResult do
  context "succeeding object" do
    subject { described_class.new("aaa", "bbb", "ccc", 0) }

    it "should set attributes" do
      expect(subject.command_line).to eq("aaa")
      expect(subject.output).to eq("bbb")
      expect(subject.error).to eq("ccc")
      expect(subject.exit_status).to eq(0)
      expect(subject.inspect).to match(/^#<AwesomeSpawn::CommandResult:[0-9a-fx]+ @exit_status=0>$/)
    end

    it "should not display sensitive information" do
      expect(subject.inspect).to_not include("aaa")
      expect(subject.inspect).to_not include("bbb")
      expect(subject.inspect).to_not include("ccc")
    end

    it { expect(subject).to be_a_success }
    it { expect(subject).not_to be_a_failure }
  end

  context "failing object" do
    subject { described_class.new("aaa", "bbb", "ccc", 1) }

    it { expect(subject).not_to be_a_success }
    it { expect(subject).to be_a_failure }
  end

  context "another failing object" do
    subject { described_class.new("aaa", "bbb", "ccc", 100) }

    it { expect(subject).not_to be_a_success }
    it { expect(subject).to be_a_failure }
  end
end
