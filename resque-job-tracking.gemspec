# -*- encoding: utf-8 -*-
require File.expand_path('../lib/resque/plugins/job_tracking/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Jason Hansen"]
  gem.email         = ["jhansen@engineyard.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "resque-job-tracking"
  gem.require_paths = ["lib"]
  gem.version       = Resque::Plugins::JobTracking::VERSION

  gem.add_dependency 'resque', '>= 1.8.0'
  gem.add_dependency 'resque-meta', '>= 1.0.0'

  gem.add_development_dependency 'rspec'
end
