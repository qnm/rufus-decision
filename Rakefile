
require 'rubygems'

require 'rake'
require 'rake/clean'
require 'rake/packagetask'
require 'rake/gempackagetask'
require 'rake/testtask'

#require 'rake/rdoctask'
require 'hanna/rdoctask'


#
# GEM SPEC

spec = Gem::Specification.new do |s|

  s.name = 'rufus-decision'
  s.version = '1.1.0'
  s.authors = [ 'John Mettraux' ]
  s.email = 'jmettraux@gmail.com'
  s.homepage = 'http://rufus.rubyforge.org/rufus-decision'
  s.platform = Gem::Platform::RUBY
  s.summary = 'CSV based Ruby decision tables'
  #s.license = 'MIT'
  s.rubyforge_project = 'rufus'

  s.require_path = 'lib'
  #s.autorequire = 'rufus-decision'
  s.test_file = 'test/test.rb'
  s.has_rdoc = true
  s.extra_rdoc_files = %w{ README.txt CHANGELOG.txt CREDITS.txt }

  %w{ rufus-dollar rufus-treechecker }.each do |d|
    s.requirements << d
    s.add_dependency d
  end

  files = FileList[ '{bin,docs,lib,test}/**/*' ]
  files.exclude('rdoc')
  s.files = files.to_a
end

#
# tasks

CLEAN.include('pkg', 'html')

task :default => [ :clean, :repackage ]


#
# TESTING

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/test.rb']
  t.verbose = true
end


#
# VERSION

task :change_version do

  version = ARGV.pop
  `sedip "s/VERSION = '.*'/VERSION = '#{version}'/" lib/rufus/decision.rb`
  `sedip "s/^  s.version = '.*'/  s.version = '#{version}'/" Rakefile`
  exit 0 # prevent rake from triggering other tasks
end


#
# PACKAGING

Rake::GemPackageTask.new(spec) do |pkg|
  #pkg.need_tar = true
end

Rake::PackageTask.new('rufus-decision', spec.version) do |pkg|

  pkg.need_zip = true
  pkg.package_files = FileList[
    'Rakefile',
    '*.txt',
    'lib/**/*',
    'test/**/*'
  ].to_a
  #pkg.package_files.delete("MISC.txt")
  class << pkg
    def package_name
      "#{@name}-#{@version}-src"
    end
  end
end


#
# DOCUMENTATION

Rake::RDocTask.new do |rd|

  rd.main = 'README.txt'
  rd.rdoc_dir = 'html/rufus-decision'
  rd.rdoc_files.include(
    'README.txt',
    'CHANGELOG.txt',
    'LICENSE.txt',
    'CREDITS.txt',
    'lib/**/*.rb')
  #rd.rdoc_files.exclude('lib/tokyotyrant.rb')
  rd.title = 'rufus-decision rdoc'
  rd.options << '-N' # line numbers
  rd.options << '-S' # inline source
end

task :rrdoc => :rdoc do
  FileUtils.cp('doc/rdoc-style.css', 'html/rufus-decision/')
end


#
# WEBSITE

task :upload_website => [ :clean, :rrdoc ] do

  account = 'jmettraux@rubyforge.org'
  webdir = '/var/www/gforge-projects/rufus'

  sh "rsync -azv -e ssh html/rufus-decision #{account}:#{webdir}/"
end

