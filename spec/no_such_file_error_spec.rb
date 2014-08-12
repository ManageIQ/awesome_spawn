require 'spec_helper'

describe AwesomeSpawn::NoSuchFileError do
  before do
    enable_spawning
  end

  context "single word command" do
    subject { caught_exception_for("falsey") }
    it { expect(subject.message).to eq("No such file or directory - falsey") }
    it { expect(subject.to_s).to eq("No such file or directory - falsey") }
    it { expect(subject).to be_a(described_class) }
  end

  context "multi word command" do
    subject { caught_exception_for("  flat   --arg 1 --arg 2") }
    it { expect(subject.message).to eq("No such file or directory - flat") }
    it { expect(subject.to_s).to eq("No such file or directory - flat") }
    it { expect(subject).to be_a(described_class) }
  end

  def caught_exception_for(command)
    AwesomeSpawn.run!(command)
  rescue => e
    return e
  end
end
