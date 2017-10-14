# frozen_string_literal: true
# -*- encoding: utf-8 -*-
require File.expand_path('../lib/tzispa/rig/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = Tzispa::Rig::GEM_NAME
  s.version     = Tzispa::Rig::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Juan Antonio Piñero']
  s.email       = ['japinero@area-integral.com']
  s.homepage    = 'https://github.com/japiber/tzispa_rig'
  s.summary     = 'General purpose template engine'
  s.description = 'General purpose template engine'
  s.licenses    = ['MIT']

  s.required_ruby_version     = '~> 2.4'

  s.add_dependency 'tzispa_utils',         '~> 0.3.5'
  s.add_dependency 'tzispa_annotations',   '~> 0.1'
  s.add_dependency 'moneta',               '~> 1.0'

  s.add_development_dependency "minitest", "~> 5.0"

  s.files         = Dir["{lib}/**/*", "{test}/**/*"] + %w(README.md CHANGELOG.md Rakefile)
  s.require_paths = ['lib']
end
