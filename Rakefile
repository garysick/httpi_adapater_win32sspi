require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rubygems'
require 'rubygems/package'

CLEAN.include('**/*.gem')

namespace :gem do
  desc "Create the httpi-adapter-win32sspi gem"
  task :create => [:clean] do
    spec = eval(IO.read('httpi-adapter-win32sspi.gemspec'))
    Gem::Package.build(spec)
  end

  desc "Install the httpi-adapter-win32sspi gem"
  task :install => [:create] do
    file = Dir["*.gem"].first
    sh "gem install #{file} -l --no-document"
  end
end

namespace :test do
  Rake::TestTask.new(:win32_adapter) do |t|
    t.test_files = FileList['test/test_httpi_adapter_win32sspi.rb']
    t.warning = true
    t.verbose = true
  end

  Rake::TestTask.new(:win32_nethttp_adapter) do |t|
    t.test_files = FileList['test/test_httpi_adapter_win32sspi_nethttp.rb']
    t.warning = true
    t.verbose = true
  end

  Rake::TestTask.new(:httpi_auth) do |t|
    t.test_files = FileList['test/test_httpi_auth.rb']
    t.warning = true
    t.verbose = true
  end

  Rake::TestTask.new(:all) do |t|
    t.test_files = FileList['test/test_httpi*']
    t.warning = true
    t.verbose = true
  end
end

task :default => 'test:all'
