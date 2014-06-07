require 'spec_helper'

describe AwesomeSpawn::CommandResult do
  context "#inspect" do
    it "will not display sensitive information" do
      str = described_class.new("aaa", "bbb", "ccc", 0).inspect

      expect(str).to_not include("aaa")
      expect(str).to_not include("bbb")
      expect(str).to_not include("ccc")
    end

    it "will know if a command succeeded" do
      expect(described_class.new("c", "o", "e", 0)).to be_a_success
      expect(described_class.new("c", "o", "e", 0)).not_to be_a_failure
    end

    it "will know if a command failed" do
      expect(described_class.new("c", "o", "e", 1)).to be_a_failure
      expect(described_class.new("c", "o", "e", 1)).not_to be_a_success
    end
  end
end
