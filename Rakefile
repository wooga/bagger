require 'bundler/gem_tasks'

require 'rake/testtask'

task :default => ['test:units']

namespace :test do
  Rake::TestTask.new(:units) do |t|
    t.libs << "test"
    t.test_files = FileList['test/*_test.rb']

    t.verbose = true
  end
end
