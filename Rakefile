require 'bundler/gem_tasks'

require 'rake/testtask'

task :default => ['test:units']

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.libs << "test"
    t.test_files = FileList['test/*_test.rb']

    t.verbose = true
  end

  desc 'run test suite with all ruby versions'
  task :multi_ruby do
    require 'yaml'
    rubies = YAML.load_file('.travis.yml')['rvm'].join(',')
    puts `rvm #{rubies} rake`
  end
end
