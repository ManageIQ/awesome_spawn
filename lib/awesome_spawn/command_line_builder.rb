require "shellwords"

module AwesomeSpawn
  class CommandLineBuilder
    # Build the full command line.
    #
    # @param [String] command The command to run
    # @param [Hash,Array] params Optional command line parameters. They can
    #   be passed as a Hash or associative Array. The values are sanitized to
    #   prevent command line injection.  Keys as Symbols are prefixed with `--`,
    #   and `_` is replaced with `-`.
    #
    #   - `{:k => "value"}`              generates `-k value`
    #   - `[[:k, "value"]]`              generates `-k value`
    #   - `{:k= => "value"}`             generates `-k=value`
    #   - `[[:k=, "value"]]`             generates `-k=value` <br /><br />
    #
    #   - `{:key => "value"}`            generates `--key value`
    #   - `[[:key, "value"]]`            generates `--key value`
    #   - `{:key= => "value"}`           generates `--key=value`
    #   - `[[:key=, "value"]]`           generates `--key=value` <br /><br />
    #
    #   - `{"--key" => "value"}`         generates `--key value`
    #   - `[["--key", "value"]]`         generates `--key value`
    #   - `{"--key=" => "value"}`        generates `--key=value`
    #   - `[["--key=", "value"]]`        generates `--key=value` <br /><br />
    #
    #   - `{:key_name => "value"}`       generates `--key-name value`
    #   - `[[:key_name, "value"]]`       generates `--key-name value`
    #   - `{:key_name= => "value"}`       generates `--key-name=value`
    #   - `[[:key_name=, "value"]]`       generates `--key-name=value` <br /><br />
    #
    #   - `{"-f" => ["file1", "file2"]}` generates `-f file1 file2`
    #   - `[["-f", "file1", "file2"]]`   generates `-f file1 file2` <br /><br />
    #
    #   - `{:key => nil}`                generates `--key`
    #   - `[[:key, nil]]`                generates `--key`
    #   - `[[:key]]`                     generates `--key` <br /><br />
    #
    #   - `{nil => ["file1", "file2"]}`  generates `file1 file2`
    #   - `[[nil, ["file1", "file2"]]]`  generates `file1 file2`
    #   - `[[nil, "file1", "file2"]]`    generates `file1 file2`
    #   - `[["file1", "file2"]]`         generates `file1 file2`
    #
    # @return [Array] An array containing the command and an array of arguments
    def build(command, params = nil)
      args = assemble_params_array(sanitize(params))
      [command.to_s, args]
    end

    private

    def assemble_params_array(sanitized_params)
      sanitized_params.flat_map do |group|
        if group.first.to_s.end_with?("=")
          # For key=value format, join them as one argument
          [group.compact.join]
        else
          # For key value format, flatten any nested arrays
          group.compact.flatten
        end
      end
    end

    def sanitize(params)
      return [] if params.nil? || params.empty?
      sanitize_associative_array(params)
    end

    def sanitize_associative_array(assoc_array)
      assoc_array.flat_map { |item| sanitize_item(item) }
    end

    def sanitize_item(item)
      case item
      when Array
        # If array contains a single Hash, process the Hash directly
        if item.length == 1 && item[0].kind_of?(Hash)
          sanitize_associative_array(item[0])
        else
          sanitize_key_values(item[0], item[1..-1])
        end
      when Hash  then sanitize_associative_array(item)
      else            sanitize_key_values(item, nil)
      end
    end

    def sanitize_key_values(key, values)
      [[sanitize_key(key), *sanitize_value(values)]]
    end

    KEY_REGEX = /^((?:--?)?)(.+?)(=?)$/

    def sanitize_key(key)
      return key if key.nil? || key.to_s.empty?
      key = convert_symbol_key(key) if key.kind_of?(Symbol)

      case key
      when String
        prefix, key, suffix = KEY_REGEX.match(key)[1..3]
        "#{prefix}#{sanitize_value(key)}#{suffix}"
      else
        sanitize_value(key)
      end
    end

    def convert_symbol_key(key)
      key = key.to_s
      dash = key =~ /^.=?$/ ? "-" : "--"
      "#{dash}#{key.tr("_", "-")}"
    end

    def sanitize_value(value)
      case value
      when Enumerable
        value.collect { |i| sanitize_value(i) }.compact
      when NilClass
        value
      else
        value.to_s
      end
    end
  end
end
