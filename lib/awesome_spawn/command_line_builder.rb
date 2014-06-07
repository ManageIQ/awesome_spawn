require "shellwords"

module AwesomeSpawn
  class CommandLineBuilder
    # Build the full command line.
    #
    # @param [String] command The command to run
    # @param [Hash,Array] params Optional command line parameters. They can
    #   be passed as a Hash or associative Array. The values are sanitized to
    #   prevent command line injection.  Keys as symbols are prefixed with `--`,
    #   and `_` is replaced with `-`.
    #
    #   - `{:key => "value"}`            generates `--key value`
    #   - `{"--key" => "value"}`         generates `--key value`
    #   - `{:key= => "value"}`           generates `--key=value`
    #   - `{"--key=" => "value"}`        generates `--key=value`
    #   - `{:key_name => "value"}`       generates `--key-name value`
    #   - `{:key => nil}`                generates `--key`
    #   - `{"-f" => ["file1", "file2"]}` generates `-f file1 file2`
    #   - `{nil => ["file1", "file2"]}`  generates `file1 file2`
    #
    # @return [String] The full command line
    def build(command, params = nil)
      return command.to_s if params.nil? || params.empty?
      "#{command} #{assemble_params(sanitize(params))}"
    end

    private

    def sanitize(params)
      return [] if params.nil? || params.empty?
      params.collect do |k, v|
        [sanitize_key(k), sanitize_value(v)]
      end
    end

    def sanitize_key(key)
      case key
      when Symbol then "--#{key.to_s.tr("_", "-")}"
      else             key
      end
    end

    def sanitize_value(value)
      case value
      when Array    then value.collect { |i| i.to_s.shellescape }
      when NilClass then value
      else               value.to_s.shellescape
      end
    end

    def assemble_params(sanitized_params)
      sanitized_params.collect do |pair|
        pair_joiner = pair.first.to_s.end_with?("=") ? "" : " "
        pair.flatten.compact.join(pair_joiner)
      end.join(" ")
    end
  end
end
