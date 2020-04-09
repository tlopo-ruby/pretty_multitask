# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "pretty_multitask/version"

Gem::Specification.new do |spec|
  spec.name          = "pretty_multitask"
  spec.version       = PrettyMultitask::VERSION
  spec.authors       = ["Tiago Lopo Da Silva"]
  spec.email         = ["tiagolopo@yahoo.com.br"]

  spec.summary       = %q{Multitask with pretty output for Rake}
  spec.description   = %q{Multitask with pretty output for Rake}
  spec.homepage      = "https://github.com/tlopo-ruby/tlopo-executor"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "tlopo-executor", "~> 0.1.0"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 12.3.3"
  spec.add_development_dependency "minitest", "~> 5.0"
end
