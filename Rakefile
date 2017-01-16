#!/usr/bin/env rake

require 'rake/clean'

begin
	require 'hoe'
rescue LoadError
	abort "This Rakefile requires 'hoe' (gem install hoe)"
end

GEMSPEC = 'loggability.gemspec'

Hoe.plugin :mercurial
Hoe.plugin :signing
Hoe.plugin :deveiate

Hoe.plugins.delete :rubyforge

hoespec = Hoe.spec 'loggability' do
	self.readme_file = 'README.rdoc'
	self.history_file = 'History.rdoc'
	self.extra_rdoc_files = FileList[ '*.rdoc' ]

	self.developer 'Michael Granger', 'ged@FaerieMUD.org'

	self.dependency 'hoe-deveiate',    '~> 0.4', :developer
	self.dependency 'hoe-bundler',     '~> 1.2', :developer
	self.dependency 'simplecov',       '~> 0.7', :developer
	self.dependency 'configurability', '~> 3.1', :developer

	self.license "Ruby"
	self.require_ruby_version( '>=1.9.3' )
	self.hg_sign_tags = true if self.respond_to?( :hg_sign_tags= )
	self.check_history_on_release = true if self.respond_to?( :check_history_on_release= )

	self.rdoc_locations << "deveiate:/usr/local/www/public/code/#{remote_rdoc_dir}"
end

ENV['VERSION'] ||= hoespec.spec.version.to_s

# Ensure the specs pass before checking in
task 'hg:precheckin' => [ :check_history, :check_manifest, :gemspec, :spec ]


desc "Build a coverage report"
task :coverage do
	ENV["COVERAGE"] = 'yes'
	Rake::Task[:spec].invoke
end
CLOBBER.include( 'coverage' )


# Use the fivefish formatter for docs generated from development checkout
if File.directory?( '.hg' )
	require 'rdoc/task'

	Rake::Task[ 'docs' ].clear
	RDoc::Task.new( 'docs' ) do |rdoc|
	    rdoc.main = "README.rdoc"
	    rdoc.rdoc_files.include( "*.rdoc", "ChangeLog", "lib/**/*.rb" )
	    rdoc.generator = :fivefish
		rdoc.title = 'Loggability'
	    rdoc.rdoc_dir = 'doc'
	end
end

task :gemspec => GEMSPEC
file GEMSPEC => [ __FILE__, 'lib/loggability.rb' ]
task GEMSPEC do |task|
	hoespec = $hoespec.spec
	hoespec.files.delete( '.gemtest' )
	hoespec.signing_key = nil
	hoespec.version = "#{hoespec.version.bump}.0.pre#{Time.now.strftime("%Y%m%d%H%M%S")}"
	hoespec.cert_chain = [ 'certs/ged.pem' ]
	File.open( task.name, 'w' ) do |fh|
		fh.write( hoespec.to_ruby )
	end
end

CLOBBER.include( GEMSPEC.to_s )

