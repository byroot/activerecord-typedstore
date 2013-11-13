require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :spec do
  task :all do
    %w(3.2 4.0 edge).each do |ar_version|
      [1, 0].each do |timezone_aware|
        command = %W{
          BUNDLE_GEMFILE=gemfiles/Gemfile.ar-#{ar_version}
          TIMEZONE_AWARE=#{timezone_aware}
          MYSQL=1
          POSTGRES=1
          rspec
        }.join(' ')
        puts command
        puts `#{command}`
      end
    end
  end
end
