# -*- encoding: utf-8 -*-
require File.expand_path('../lib/whacamole/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name                = "whacamole"

  gem.authors             = ["Chris Doyle"]
  gem.email               = ["archslide@gmail.com"]
  gem.email               = "archslide@gmail.com"

  gem.description         = "Whacamole"
  gem.summary             = ""
  gem.homepage            = "http://github.com/arches/whacamole"
  gem.version             = Whacamole::VERSION
  gem.license             = 'MIT'

  gem.files               = `git ls-files`.split($\)
  gem.test_files          = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths       = ["lib"]

  gem.add_development_dependency 'cucumber', '~> 1.2.1'
  gem.add_development_dependency 'rspec', '~> 2.11.0'
  gem.add_development_dependency 'rake', '~> 0.9.2'
end
