# AwesomeSpawn

AwesomeSpawn is a module that provides some useful features over Ruby's Kernel.spawn.

Some additional features include...
- Parameter passing as a Hash or associative Array sanitizing them to prevent command line injection.
- Results returned as an object giving access to the output stream, error stream, and exit status.
- Optionally raising an exception when exit status is not 0.

## Usage

`.run` or `.run!` with normal output

```ruby
result = AwesomeSpan.run('echo Hi')
# => #<AwesomeSpawn::CommandResult:0x007f9d1d197320 @exit_status=0>
result.output       # => "Hi\n"
result.error        # => ""
result.exit_status  # => 0
```

`.run` or `.run!` with error output as well

```ruby
result = AwesomeSpawn.run('echo Hi; echo "Hi2" 1>&2')
# => <AwesomeSpawn::CommandResult:0x007ff64b98d930 @exit_status=0>
result.output       # => "Hi\n"
result.error        # => "Hi2\n"
result.exit_status  # => 0
```

`.run` with exit status that is not 0

```ruby
result = AwesomeSpawn.run('false')
#<AwesomeSpawn::CommandResult:0x007ff64b971410 @exit_status=1>
result.exit_status  # => 1
```

`.run!` with exit status that is not 0

```ruby
error = AwesomeSpawn.run!('false') rescue $!
# => #<AwesomeSpawn::CommandResultError: false exit code: 1>
error.message # => false exit code: 1
error.result  # => #<AwesomeSpawn::CommandResult:0x007ff64ba08018 @exit_status=1>
```

`.run` or `.run!` with parameters sanitized

```ruby
result = AwesomeSpawn.run('echo', :params => {"--out" => "; rm /some/file"})
# => #<AwesomeSpawn::CommandResult:0x007ff64baa6650 @exit_status=0>
result.command_line
# => "echo --out \\;\\ rm\\ /some/file"
```

## Installation

Add this line to your application's Gemfile:

    gem 'awesome_spawn'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install awesome_spawn

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
