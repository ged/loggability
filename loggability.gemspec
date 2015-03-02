# -*- encoding: utf-8 -*-
# stub: loggability 0.12.0.pre20150301211824 ruby lib

Gem::Specification.new do |s|
  s.name = "loggability"
  s.version = "0.12.0.pre20150301211824"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Michael Granger"]
  s.cert_chain = ["/Users/ged/.gem/ged-public_gem_cert.pem"]
  s.date = "2015-03-02"
  s.description = "A composable logging system built on the standard Logger library.\n\nYou can add Loggability to large libraries and systems, then hook everything\nup later when you know where you want logs to be written, at what level of\nseverity, and in which format.\n\nAn example:\n\n    # Load a bunch of libraries that use Loggability\n    require 'strelka'\n    require 'inversion'\n    require 'treequel'\n    require 'loggability'\n    \n    # Set up our own library\n    module MyProject\n        extend Loggability\n        log_as :my_project\n    \n        class Server\n            extend Loggability\n            log_to :my_project\n    \n            def initialize\n                self.log.debug \"Listening.\"\n            end\n        end\n    \n    end\n    \n    # Now tell everything that's using Loggability to log to an HTML\n    # log file at INFO level\n    Loggability.write_to( '/usr/local/www/htdocs/log.html' )\n    Loggability.format_as( :html )\n    Loggability.level = :info"
  s.email = ["ged@FaerieMUD.org"]
  s.extra_rdoc_files = ["History.rdoc", "Manifest.txt", "README.rdoc", "History.rdoc", "README.rdoc"]
  s.files = [".simplecov", "ChangeLog", "History.rdoc", "Manifest.txt", "README.rdoc", "Rakefile", "lib/loggability.rb", "lib/loggability/constants.rb", "lib/loggability/formatter.rb", "lib/loggability/formatter/color.rb", "lib/loggability/formatter/default.rb", "lib/loggability/formatter/html.rb", "lib/loggability/logclient.rb", "lib/loggability/logger.rb", "lib/loggability/loghost.rb", "lib/loggability/override.rb", "lib/loggability/spechelpers.rb", "spec/helpers.rb", "spec/loggability/formatter/color_spec.rb", "spec/loggability/formatter/html_spec.rb", "spec/loggability/formatter_spec.rb", "spec/loggability/logger_spec.rb", "spec/loggability/override_spec.rb", "spec/loggability/spechelpers_spec.rb", "spec/loggability_spec.rb"]
  s.homepage = "http://deveiate.org/projects/loggability"
  s.licenses = ["Ruby"]
  s.rdoc_options = ["--main", "README.rdoc"]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3")
  s.rubygems_version = "2.4.5"
  s.signing_key = "/Volumes/Keys/ged-private_gem_key.pem"
  s.summary = "A composable logging system built on the standard Logger library"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>, ["~> 0.6"])
      s.add_development_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_development_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_development_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_development_dependency(%q<configurability>, ["~> 2.0"])
      s.add_development_dependency(%q<hoe>, ["~> 3.13"])
    else
      s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>, ["~> 0.6"])
      s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
      s.add_dependency(%q<rdoc>, ["~> 4.0"])
      s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
      s.add_dependency(%q<simplecov>, ["~> 0.7"])
      s.add_dependency(%q<configurability>, ["~> 2.0"])
      s.add_dependency(%q<hoe>, ["~> 3.13"])
    end
  else
    s.add_dependency(%q<hoe-mercurial>, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>, ["~> 0.6"])
    s.add_dependency(%q<hoe-highline>, ["~> 0.2"])
    s.add_dependency(%q<rdoc>, ["~> 4.0"])
    s.add_dependency(%q<hoe-bundler>, ["~> 1.2"])
    s.add_dependency(%q<simplecov>, ["~> 0.7"])
    s.add_dependency(%q<configurability>, ["~> 2.0"])
    s.add_dependency(%q<hoe>, ["~> 3.13"])
  end
end
