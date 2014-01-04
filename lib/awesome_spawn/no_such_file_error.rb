module AwesomeSpawn
  class NoSuchFileError < Errno::ENOENT
    def initialize(message)
      super(message.split("No such file or directory -").last.split(" ").first)
    end

    def self.detected?(message)
      message.start_with?("No such file or directory -")
    end
  end
end
