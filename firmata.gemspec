# -*- encoding: utf-8 -*-
require File.expand_path('../lib/firmata/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["'Mike Breen'"]
  gem.email         = ["hardbap@gmail.com"]
  gem.description   = %q{A lib for working with the Firmata protocol in Ruby.}
  gem.summary       = %q{}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "firmata"
  gem.require_paths = ["lib"]
  gem.version       = Firmata::VERSION

  gem.add_development_dependency("pry")

  gem.add_runtime_dependency("serialport", ["~> 1.3.1"])
  gem.add_runtime_dependency("event_spitter")
end
