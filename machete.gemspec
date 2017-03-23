# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'machete/version'

Gem::Specification.new do |spec|
  spec.name          = 'machete'
  spec.version       = Machete::VERSION
  spec.authors       = ['Cloud Foundry Buildpacks Team']
  spec.email         = ['cf-buildpacks-eng@pivotal.io']
  spec.summary       = 'Machete is the buildpack testing library for Cloud Foundry Buildpacks'
  spec.description   = 'Machete is the buildpack testing library for Cloud Foundry Buildpacks'
  spec.homepage      = ''
  spec.license       = 'Apache 2.0'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.2'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'

  spec.add_runtime_dependency 'httparty'
  spec.add_runtime_dependency 'childprocess'
end
