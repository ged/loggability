# -*- encoding: utf-8 -*-
# stub: loggability 0.15.0.pre20170204094808 ruby lib

Gem::Specification.new do |s|
  s.name = "loggability".freeze
  s.version = "0.15.0.pre20170204094808"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.cert_chain = ["certs/ged.pem".freeze]
  s.date = "2017-02-04"
  s.description = "A composable logging system built on the standard Logger library.\n\nYou can add Loggability to large libraries and systems, then hook everything\nup later when you know where you want logs to be written, at what level of\nseverity, and in which format.\n\nAn example:\n\n    # Load a bunch of libraries that use Loggability\n    require 'strelka'\n    require 'inversion'\n    require 'treequel'\n    require 'loggability'\n    \n    # Set up our own library\n    module MyProject\n        extend Loggability\n        log_as :my_project\n    \n        class Server\n            extend Loggability\n            log_to :my_project\n    \n            def initialize\n                self.log.debug \"Listening.\"\n            end\n        end\n    \n    end\n    \n    # Now tell everything that's using Loggability to log to an HTML\n    # log file at INFO level\n    Loggability.write_to( '/usr/local/www/htdocs/log.html' )\n    Loggability.format_as( :html )\n    Loggability.level = :info".freeze
  s.email = ["ged@FaerieMUD.org".freeze]
  s.extra_rdoc_files = ["History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "History.rdoc".freeze, "README.rdoc".freeze]
  s.files = [".simplecov".freeze, "ChangeLog".freeze, "History.rdoc".freeze, "Manifest.txt".freeze, "README.rdoc".freeze, "Rakefile".freeze, "lib/loggability.rb".freeze, "lib/loggability/constants.rb".freeze, "lib/loggability/formatter.rb".freeze, "lib/loggability/formatter/color.rb".freeze, "lib/loggability/formatter/default.rb".freeze, "lib/loggability/formatter/html.rb".freeze, "lib/loggability/logclient.rb".freeze, "lib/loggability/logger.rb".freeze, "lib/loggability/loghost.rb".freeze, "lib/loggability/override.rb".freeze, "lib/loggability/spechelpers.rb".freeze, "spec/helpers.rb".freeze, "spec/loggability/formatter/color_spec.rb".freeze, "spec/loggability/formatter/html_spec.rb".freeze, "spec/loggability/formatter_spec.rb".freeze, "spec/loggability/logger_spec.rb".freeze, "spec/loggability/loghost_spec.rb".freeze, "spec/loggability/override_spec.rb".freeze, "spec/loggability/spechelpers_spec.rb".freeze, "spec/loggability_spec.rb".freeze]
  s.homepage = "http://deveiate.org/projects/loggability".freeze
  s.licenses = ["Ruby".freeze]
  s.rdoc_options = ["--main".freeze, "README.rdoc".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "2.6.8".freeze
  s.summary = "A composable logging system built on the standard Logger library".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_development_dependency(%q<hoe-deveiate>.freeze, ["~> 0.8"])
      s.add_development_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_development_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.7"])
      s.add_development_dependency(%q<configurability>.freeze, ["~> 3.1"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.15"])
      s.add_development_dependency(%q<concurrent-ruby>.freeze, ["~> 1.1"])
      s.add_development_dependency('pry')
      s.add_development_dependency('webmock')
    else
      s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
      s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.8"])
      s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
      s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
      s.add_dependency(%q<configurability>.freeze, ["~> 3.1"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.15"])
    end
  else
    s.add_dependency(%q<hoe-mercurial>.freeze, ["~> 1.4"])
    s.add_dependency(%q<hoe-deveiate>.freeze, ["~> 0.8"])
    s.add_dependency(%q<hoe-highline>.freeze, ["~> 0.2"])
    s.add_dependency(%q<hoe-bundler>.freeze, ["~> 1.2"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_dependency(%q<configurability>.freeze, ["~> 3.1"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 4.0"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.15"])
  end
end
