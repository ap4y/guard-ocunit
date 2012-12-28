# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'guard/ocunit/version'

Gem::Specification.new do |s|
  s.name        = 'guard-ocunit'
  s.version     = Guard::OCUnitVersion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Arthur Evstifeev']
  s.email       = ['lod@pisem.net']
  s.homepage    = 'https://github.com/ap4y/guard-ocunit'
  s.summary     = 'Guard gem for OCUnit'
  s.description = 'Guard::OCUnit automatically runs your tests.'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'guard', '>= 1.1'
  s.add_dependency 'open4', '>= 1.3'
  s.add_dependency 'xcodebuild-rb', '>= 0.3'
  s.add_dependency 'colored', '>= 1.2'

  s.add_development_dependency 'bundler',     '~> 1.1'
  s.add_development_dependency 'rspec',       '~> 2.11'
  s.add_development_dependency 'guard-rspec', '~> 1.1'

  s.files        = Dir.glob('{lib}/**/*') + %w[LICENSE README.md]
  s.require_path = 'lib'
end
