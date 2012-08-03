#!/usr/bin/env rake

require 'rake/clean'

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires 'hoe' (gem install hoe)"
end

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :deveiate

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'loggability' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = FileList[ '*.rdoc' ]

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency 'hoe-deveiate',    '~> 0.1', :developer
	self.dependency 'simplecov',       '~> 0.6', :developer
	self.dependency 'configurability', '~> 1.2', :developer

	self.spec_extras[:licenses] = ["Ruby"]
	self.spec_extras[:rdoc_options] = ['-f', 'fivefish', '-t', 'Loggability Toolkit']
	self.require_ruby_version( '>=1.8.7' )
	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.check_history_on_release = true if self.respond_to?( :check_history_on_release= )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => [ :check_history, :check_manifest, :spec ]


desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end

