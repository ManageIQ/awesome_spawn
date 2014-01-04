require 'spec_helper'

describe AwesomeSpawn::CommandResult do
  context "#inspect" do
    it "will not display sensitive information" do
      str = described_class.new("aaa", "bbb", "ccc", 0).inspect

      expect(str.include?("aaa")).to be_false
      expect(str.include?("bbb")).to be_false
      expect(str.include?("ccc")).to be_false
    end
  end
end
