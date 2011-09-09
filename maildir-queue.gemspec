# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = 'maildir-queue'
  s.version = '1.0.1'

  s.authors = ["Aaron Suggs"]
  s.description = 'A simple queue API with a maildir backend. Also includes an HTTP API'
  s.email = "aaron@ktheory.com"
  s.required_rubygems_version = ">= 1.3.5"

  s.files = Dir.glob("{bin,lib}/**/*") + %w(LICENSE README.rdoc Rakefile)
  s.homepage = 'http://github.com/ktheory/maildir-queue'
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.summary = %q{A simple queue API with a maildir backend.}
  s.test_files = Dir.glob("test/**/*")

  s.add_development_dependency 'rake'
  s.add_development_dependency 'shoulda'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'ktheory-fakefs'

  s.add_dependency 'maildir', ">= 1.0.0"
  s.add_dependency 'sinatra'
  s.add_dependency 'json'

end
