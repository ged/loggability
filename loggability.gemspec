# -*- encoding: utf-8 -*-
# stub: loggability 0.17.0.pre.20200227170929 ruby lib

Gem::Specification.new do |s|
  s.name = "loggability".freeze
  s.version = "0.17.0.pre.20200227170929"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Granger".freeze]
  s.date = "2020-02-27"
  s.description = "A composable logging system built on the standard Logger library.".freeze
  s.email = ["ged@faeriemud.org".freeze]
  s.files = [".simplecov".freeze, "History.rdoc".freeze, "Manifest.txt".freeze, "README.md".freeze, "Rakefile".freeze, "lib/loggability.rb".freeze, "lib/loggability/constants.rb".freeze, "lib/loggability/formatter.rb".freeze, "lib/loggability/formatter/color.rb".freeze, "lib/loggability/formatter/default.rb".freeze, "lib/loggability/formatter/html.rb".freeze, "lib/loggability/formatter/structured.rb".freeze, "lib/loggability/log_device.rb".freeze, "lib/loggability/log_device/appending.rb".freeze, "lib/loggability/log_device/datadog.rb".freeze, "lib/loggability/log_device/file.rb".freeze, "lib/loggability/log_device/http.rb".freeze, "lib/loggability/logclient.rb".freeze, "lib/loggability/logger.rb".freeze, "lib/loggability/loghost.rb".freeze, "lib/loggability/override.rb".freeze, "lib/loggability/spechelpers.rb".freeze, "spec/helpers.rb".freeze, "spec/loggability/formatter/color_spec.rb".freeze, "spec/loggability/formatter/default_spec.rb".freeze, "spec/loggability/formatter/html_spec.rb".freeze, "spec/loggability/formatter/structured_spec.rb".freeze, "spec/loggability/formatter_spec.rb".freeze, "spec/loggability/log_device/appending_spec.rb".freeze, "spec/loggability/log_device/datadog_spec.rb".freeze, "spec/loggability/log_device/file_spec.rb".freeze, "spec/loggability/log_device/http_spec.rb".freeze, "spec/loggability/logger_spec.rb".freeze, "spec/loggability/loghost_spec.rb".freeze, "spec/loggability/override_spec.rb".freeze, "spec/loggability/spechelpers_spec.rb".freeze, "spec/loggability_spec.rb".freeze]
  s.homepage = "https://hg.sr.ht/~ged/Loggability".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.5".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A composable logging system built on the standard Logger library.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake-deveiate>.freeze, ["~> 0.7"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_development_dependency(%q<configurability>.freeze, ["~> 4.0"])
    s.add_development_dependency(%q<timecop>.freeze, ["~> 0.9"])
    s.add_development_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.4"])
    s.add_development_dependency(%q<concurrent-ruby>.freeze, ["~> 1.1"])
  else
    s.add_dependency(%q<rake-deveiate>.freeze, ["~> 0.7"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.7"])
    s.add_dependency(%q<configurability>.freeze, ["~> 4.0"])
    s.add_dependency(%q<timecop>.freeze, ["~> 0.9"])
    s.add_dependency(%q<rdoc-generator-fivefish>.freeze, ["~> 0.4"])
    s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.1"])
  end
end
