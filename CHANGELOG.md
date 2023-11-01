# Changelog
All notable changes to this project will be documented in this file.

## [Unreleased]

## [v1.6.0] - 2023-11-01
### Added
- Add `CommandResult#pid` [[#49](https://github.com/ManageIQ/awesome_spawn/pull/49)]
- Add `AwesomeSpawn.run_detached` [[#32](https://github.com/ManageIQ/awesome_spawn/pull/32)]
- Add `SpecHelper.disable_spawning` helper method [[#66](https://github.com/ManageIQ/awesome_spawn/pull/66)]
- Add support for Ruby versions 2.5 to 3.2 [[#56](https://github.com/ManageIQ/awesome_spawn/pull/56), [#62](https://github.com/ManageIQ/awesome_spawn/pull/62), [#70](https://github.com/ManageIQ/awesome_spawn/pull/70)]

### Removed
- Remove support for old Ruby versions 2.0 to 2.4 [[#56](https://github.com/ManageIQ/awesome_spawn/pull/56)]

## [v1.5.0] - 2020-02-04
### Added
- Add `:combined_output` option to merge STDOUT and STDERR streams [[#48](https://github.com/ManageIQ/awesome_spawn/pull/48)]
- Publish STDERR when error occurs on command execution [[#39](https://github.com/ManageIQ/awesome_spawn/pull/39)]
- On error log STDOUT if STDERR is empty [[#45](https://github.com/ManageIQ/awesome_spawn/pull/45)]
- Add support for Ruby 2.3 and 2.4 [[#40](https://github.com/ManageIQ/awesome_spawn/pull/40)]

### Fixed
- Make `AwesomeSpawn::SpecHelper` work properly [[#46](https://github.com/ManageIQ/awesome_spawn/pull/46)]
- Don't include spec in gem [[#47](https://github.com/ManageIQ/awesome_spawn/pull/47)]

### Removed
- Remove support for Ruby 1.9 [[#38](https://github.com/ManageIQ/awesome_spawn/pull/38)]

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

[Unreleased]: https://github.com/ManageIQ/awesome_spawn/compare/v1.6.0...HEAD
[v1.6.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.5.0...v1.6.0
[v1.5.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.4.0...v1.5.0
[v1.4.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.3.0...v1.4.0
[v1.3.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.2.1...v1.3.0
[v1.2.1]: https://github.com/ManageIQ/awesome_spawn/compare/v1.2.0...v1.2.1
[v1.2.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.1.1...v1.2.0
[v1.1.1]: https://github.com/ManageIQ/awesome_spawn/compare/v1.1.0...v1.1.1
[v1.1.0]: https://github.com/ManageIQ/awesome_spawn/compare/v1.0.0...v1.1.0
