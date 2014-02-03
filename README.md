# AwesomeSpawn

[![Gem Version](https://badge.fury.io/rb/awesome_spawn.png)](http://badge.fury.io/rb/awesome_spawn)
[![Build Status](https://travis-ci.org/ManageIQ/awesome_spawn.png)](https://travis-ci.org/ManageIQ/awesome_spawn)
[![Code Climate](https://codeclimate.com/github/ManageIQ/awesome_spawn.png)](https://codeclimate.com/github/ManageIQ/awesome_spawn)
[![Coverage Status](https://coveralls.io/repos/ManageIQ/awesome_spawn/badge.png?branch=master)](https://coveralls.io/r/ManageIQ/awesome_spawn)
[![Dependency Status](https://gemnasium.com/ManageIQ/awesome_spawn.png)](https://gemnasium.com/ManageIQ/awesome_spawn)

AwesomeSpawn is a module that provides some useful features over Ruby's Kernel.spawn.

Some additional features include...

- Parameter passing as a Hash or associative Array sanitizing them to prevent command line injection.
- Ability to pass the contents of stdin as a String.
- Results returned as an object giving access to the output stream, error stream, and exit status.
- Optionally raising an exception when exit status is not 0.

## Usage

See the [YARD documentation](http://rubydoc.info/gems/awesome_spawn)

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
