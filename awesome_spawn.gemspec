# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'awesome_spawn/version'

Gem::Specification.new do |spec|
  authors = {
    "Jason Frey"     => "jfrey@redhat.com",
    "Brandon Dunne"  => "bdunne@redhat.com",
    "Joe Rafaniello" => "jrafanie@redhat.com",
    "Mo Morsi"       => "mmorsi@redhat.com"
  }

  spec.name          = "awesome_spawn"
  spec.version       = AwesomeSpawn::VERSION
  spec.authors       = authors.keys
  spec.email         = authors.values
  spec.description   = %q{AwesomeSpawn is a module that provides some useful features over Ruby's Kernel.spawn.}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/ManageIQ/awesome_spawn"
  spec.license       = "MIT"

  spec.files         = `git ls-files -- lib/*`.split("\n")
  spec.files        += %w[.yardopts README.md LICENSE.txt]
  spec.executables   = `git ls-files -- bin/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "manageiq-style"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
