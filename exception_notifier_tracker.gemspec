
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "exception_notifier_tracker/version"


Gem::Specification.new do |spec|
  spec.name          = "exception_notifier_tracker"
  spec.version       = ExceptionNotifierTracker::VERSION
  spec.authors       = ["Hendry Firman"]
  spec.email         = ["hendry@kopihub.com", "hendryfirman86@gmail.com"]

  spec.summary       = %q{Tracking exceptions for Rails application store them in JSON}
  spec.description   = %q{Tracking exceptions for Rails application store them in JSON send to apps tracker}
  spec.homepage      = "https://www.lipsiagroup.com/it"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "README.md"]

  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  # spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
end
