require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :custom_spec do
  system 'rake spec'
end
task :default => :custom_spec
