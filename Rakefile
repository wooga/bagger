require 'bundler/gem_tasks'

require 'rake/testtask'

task :default => ['test:units']

def rubies
  require 'yaml'
  rubies = YAML.load_file('.travis.yml')['rvm']
end

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.libs << "test"
    t.test_files = FileList['test/*_test.rb']

    t.verbose = true
  end

  desc 'run test suite with all ruby versions'
  task :multi_ruby do
    rubies.each do |ruby_version|
      puts `rvm use #{ruby_version} && rake`
    end
  end
end

desc 'run bundle install for all rubies'
task :prepare_rubies do
  rubies.each do |ruby_version|
    puts `rvm use #{ruby_version} && gem install bundler && bundle`
  end
end
