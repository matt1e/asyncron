# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("../lib", __FILE__)

require "asyncron/version"

Gem::Specification.new do |s|
  s.name = "asyncron"
  s.version = Asyncron::VERSION
  s.summary = "Asynchronous execution of cron jobs"
  s.description = "Takes a cron expression, a payload and a callback for " \
    "later execution"
  s.authors = ["Matthias Geier"]
  s.homepage = "https://github.com/matthias-geier/asyncron"
  s.license = "BSD-2-Clause"
  s.files = Dir["lib/**/*"]
  s.test_files = Dir["test/**/*"]
  s.add_dependency "redis", "~> 3"
  s.add_development_dependency "minitest", "~> 5"
end
