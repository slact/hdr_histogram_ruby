require "bundler/gem_tasks"
require "rake/extensiontask"
require 'rake/testtask'
task :default => :test
Rake::ExtensionTask.new 'ruby_hdr_histogram'


Rake::TestTask.new do |t|
    t.libs << "test"
    t.pattern = "test/*_test.rb"
end
