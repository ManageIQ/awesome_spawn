# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]

## [v1.4.0] - 2016-01-28
- Added environment variable support with key `:env`
- Single letter symbols become short parameters `{:a => 5}` becomes `-a 5`.
- Introduce `AwesomeSpawn::SpecHelper` for `disable_spawning` in tests.
 
## [v1.3.0] - 2015-01-28
### Added
- This CHANGELOG file to help users track progress of this gem. More information can be found at http://keepachangelog.com/
- Fix rspec deprecation warnings
- Logging errors in `run!` and a default NullLogger.  Set logger with `AwesomeSpawn.logger = Logger.new(STDOUT)`

## [v1.2.1] - 2014-07-17
- Fix hashes nested in arrays.

## [v1.2.0] - 2014-07-08
- Use `Open3#capture3` instead of `Kernel#spawn` and `Thread`.
- added `CommandResult#success?` and `CommandResult#failure?`

## [v1.1.1] - 2014-02-03
- Gemspec fixes

## [v1.1.0] - 2014-02-03
- Introduce symbols converted into long parameters. e.g. `{:width => 5` to `--width 5`.
- Introduce `:in_data` to pass in stdin.

## v1.0.0 - 2014-01-04

[Unreleased]: https://github.com/ManageIQ/awesome_spawn/compare/v1.4.0...HEAD
[v1.4.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.2.1...v1.3.0
[v1.2.1]: https://github.com/ManageIQ/awesome_spawn/compare/v1.2.0...v1.2.1
[v1.2.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.1.1...v1.2.0
[v1.1.1]: https://github.com/ManageIQ/awesome_spawn/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.0.0...v1.1.0
