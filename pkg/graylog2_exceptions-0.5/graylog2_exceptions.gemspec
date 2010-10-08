# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{graylog2_exceptions}
  s.version = "0.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lennart Koopmann"]
  s.date = %q{2010-10-08}
  s.description = %q{A Rack middleware that sends every Exception as GELF message to your Graylog2 server}
  s.email = %q{lennart@socketfeed.com}
  s.extra_rdoc_files = ["lib/graylog_exceptions.rb"]
  s.files = ["Rakefile", "lib/graylog_exceptions.rb", "Manifest", "graylog2_exceptions.gemspec"]
  s.homepage = %q{http://www.graylog2.org/}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Graylog2_exceptions"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{graylog2_exceptions}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A Rack middleware that sends every Exception as GELF message to your Graylog2 server}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<gelf>, [">= 0"])
    else
      s.add_dependency(%q<gelf>, [">= 0"])
    end
  else
    s.add_dependency(%q<gelf>, [">= 0"])
  end
end
