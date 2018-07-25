# -*- encoding: utf-8 -*-
# stub: fluent-plugin-dstat 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "fluent-plugin-dstat"
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Shunsuke Mikami"]
  s.email = "shun0102@gmail.com"
  s.license = "Apache-2.0"
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]
  s.files = [
    ".document",
    "AUTHORS",
    "Gemfile",
    "LICENSE.txt",
    "README.md",
    "Rakefile",
    "VERSION",
    "fluent-plugin-dstat.gemspec",
    "lib/fluent/plugin/in_dstat.rb",
    "test/helper.rb",
    "test/plugin/test_in_dstat.rb"
  ]
  s.homepage = "http://github.com/shun0102/fluent-plugin-dstat"
  s.rubygems_version = "2.4.5"
  s.summary = "Dstat Input plugin for Fluent event collector"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<fluentd>, [">= 0.14.0", "< 2"])
      s.add_runtime_dependency(%q<rdoc>, [">= 0"])
      s.add_development_dependency(%q<test-unit>, [">= 3.0.0"])
      s.add_development_dependency(%q<bundler>, ["~> 1.0"])
      s.add_development_dependency(%q<rake>, ["~> 12.0"])
    else
      s.add_runtime_dependency(%q<fluentd>, [">= 0.14.0", "< 2"])
      s.add_runtime_dependency(%q<rdoc>, [">= 0"])
      s.add_dependency(%q<test-unit>, [">= 3.0.0"])
      s.add_dependency(%q<bundler>, ["~> 1.0"])
      s.add_dependency(%q<rake>, ["~> 12.0"])
    end
  else
    s.add_runtime_dependency(%q<fluentd>, [">= 0.14.0", "< 2"])
    s.add_runtime_dependency(%q<rdoc>, [">= 0"])
    s.add_dependency(%q<test-unit>, [">= 3.0.0"])
    s.add_dependency(%q<bundler>, ["~> 1.0"])
    s.add_dependency(%q<rake>, ["~> 12.0"])
  end
end
