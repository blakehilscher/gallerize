# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "gallerize_cli"

Gem::Specification.new do |s|
  s.name = "gallerize-cli"
  s.version = GallerizeCli::VERSION
  s.authors = ["Blake Hilscher"]
  s.email = ["blake@hilscher.ca"]
  s.homepage = "http://blake.hilscher.ca/"
  s.license = "MIT"
  s.summary = "Generate a static gallery from a folder of images."
  s.description = "https://github.com/blakehilscher/gallerize"

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = ["gallerize_cli"]
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'mini_magick', '3.7.0'
  s.add_runtime_dependency 'parallel', '1.0.0'
  s.add_runtime_dependency 'sass', '3.4.7'
  s.add_runtime_dependency 'uglifier'

  s.add_development_dependency "pry", "~> 0.9"
end