require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :gemfiles do
  task :update do
    Dir[File.expand_path('gemfiles/*')].each do |file|
      next if file.end_with?('.lock')
      command = %W{
        BUNDLE_GEMFILE='#{file}'
        bundle update
      }.join(' ')
      puts command
      system(command)
    end
  end
end

namespace :spec do
  task :all do
    %w(4.2 5.0 5.1).each do |ar_version|
      [1, 0].each do |timezone_aware|
        command = %W{
          BUNDLE_GEMFILE=gemfiles/Gemfile.ar-#{ar_version}
          TIMEZONE_AWARE=#{timezone_aware}
          MYSQL=1
          POSTGRES=1
          rspec
        }.join(' ')
        puts command
        system(command)
      end
    end
  end
end
