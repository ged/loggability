# -*- encoding: utf-8 -*-
# stub: loggability 0.15.0.pre.20191025175112 ruby lib

Gem::Specification.new do |s|
  s.name = "loggability".freeze
  s.version = "0.15.0.pre.20191025175112"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2019-10-25"
  s.description = "A composable logging system built on the standard Logger library.".freeze
  s.email = ["ged@faeriemud.org".freeze]
  s.files = [".simplecov".freeze, "ChangeLog".freeze, "History.rdoc".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/loggability.rb".freeze, "lib/loggability/constants.rb".freeze, "lib/loggability/formatter.rb".freeze, "lib/loggability/formatter/color.rb".freeze, "lib/loggability/formatter/default.rb".freeze, "lib/loggability/formatter/html.rb".freeze, "lib/loggability/formatter/structured.rb".freeze, "lib/loggability/logclient.rb".freeze, "lib/loggability/logger.rb".freeze, "lib/loggability/loghost.rb".freeze, "lib/loggability/override.rb".freeze, "lib/loggability/spechelpers.rb".freeze, "spec/helpers.rb".freeze, "spec/loggability/formatter/color_spec.rb".freeze, "spec/loggability/formatter/default_spec.rb".freeze, "spec/loggability/formatter/html_spec.rb".freeze, "spec/loggability/formatter/structured_spec.rb".freeze, "spec/loggability/formatter_spec.rb".freeze, "spec/loggability/logger_spec.rb".freeze, "spec/loggability/loghost_spec.rb".freeze, "spec/loggability/override_spec.rb".freeze, "spec/loggability/spechelpers_spec.rb".freeze, "spec/loggability_spec.rb".freeze]
  s.homepage = "http://deveiate.org/projects/loggability".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A composable logging system built on the standard Logger library.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake-deveiate>.freeze, ["~> 0.4"])
      s.add_runtime_dependency(%q<simplecov>.freeze, ["~> 0.7"])
      s.add_runtime_dependency(%q<configurability>.freeze, ["~> 3.1"])
      s.add_runtime_dependency(%q<timecop>.freeze, ["~> 0.9"])
      s.add_runtime_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.4"])
    else
      s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.4"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
      s.add_dependency(%q<configurability>.freeze, ["~> 3.1"])
      s.add_dependency(%q<timecop>.freeze, ["~> 0.9"])
      s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.4"])
    end
  else
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.4"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_dependency(%q<configurability>.freeze, ["~> 3.1"])
    s.add_dependency(%q<timecop>.freeze, ["~> 0.9"])
    s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.4"])
  end
end
