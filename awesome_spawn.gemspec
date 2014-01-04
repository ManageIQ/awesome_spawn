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

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "redcarpet"
end
