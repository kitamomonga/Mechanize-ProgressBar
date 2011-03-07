require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "mechanize-progressbar"
  gem.homepage = "http://github.com/kitamomonga/mechanize-progressbar"
  gem.license = "GPL-2"
  gem.summary = "Mechanize-Progressbar provides ProgressBar for Mechanize#get and Link#click. requires 'progressbar' gem."
  gem.description = "Mechanize-Progressbar shows ProgressBar when HTTP GET access of Mechanize(Mechanize#get, Page::Link#click, response of Form#submit). It requires 'progressbar' gem. HTTP POST is not supported."
  gem.email = "kitamomonga@gmail.com"
  gem.authors = ["kitamomonga"]
  # See ./Gemfile
  # gem.add_runtime_dependency 'mechanize', '>= 1.0.0'
  # gem.add_runtime_dependency 'progressbar', '>= 0.9.0'
  # gem.add_development_dependency 'rspec', '> 1.2.3'
  # gem.add_development_dependency 'webmock', '> 1.6.1'
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "mechanize-progressbar #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
