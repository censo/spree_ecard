# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'spree_ecard/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_ecard'
  s.version     = SpreeEcard::VERSION
  s.summary     = 'Ecard payment system for Spree'

  s.author        = "Adam Migodziński"
  s.email         = "adam.migodzinski@goodylabs.com"

  s.homepage      = "https://goodylabs.com"
  s.license       = "MIT"

  s.required_ruby_version = '>= 2.2.2'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency('spree_core', '>= 3.1.0')
  s.add_dependency('haml')

  s.add_development_dependency "bundler", "~> 1.11"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "rspec", "~> 3.0"
end