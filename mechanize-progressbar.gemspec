# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mechanize/progressbar/version'
require 'date'

Gem::Specification.new do |spec|
  spec.name          = "mechanize-progressbar"
  spec.version       = Mechanize::Progressbar::VERSION
  spec.date          = Date.today.to_s
  spec.authors       = ["kitamomonga"]
  spec.email         = ["kitamomonga@gmail.com"]
  spec.summary       = %q{Progress bar for Mechanize}
  spec.description   = %q{Mechanize-Progressbar provides ProgressBar for Mechanize#get and Link#click..}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.required_ruby_version     = '> 1.9'

  spec.add_runtime_dependency 'mechanize', '~> 2.7'
  spec.add_runtime_dependency 'progressbar', '~> 0.21.0'

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 1.6.1'
end
