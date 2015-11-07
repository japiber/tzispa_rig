# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tzispa/rig/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = Tzispa::Rig::GEM_NAME
  s.version     = Tzispa::Rig::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Juan Antonio Piñero']
  s.email       = ['japinero@area-integral.com']
  s.homepage    = 'https://www.area-integral.com'
  s.summary     = 'General purpose template engine'
  s.description = 'General purpose template engine'
  s.licenses    = ['MIT']

  s.required_rubygems_version = '~> 2.0'
  s.required_ruby_version     = '~> 2.0'

  s.add_dependency 'tzispa_helpers', '~> 0.1'
  s.add_dependency 'tzispa_utils',   '~> 0.1'

  s.files         = Dir.glob("{lib}/**/*") + %w(README.md CHANGELOG.md)
  s.require_paths = ['lib']
end
