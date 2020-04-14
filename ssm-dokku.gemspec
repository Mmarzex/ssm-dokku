require_relative 'lib/ssm/dokku/version'

Gem::Specification.new do |spec|
  spec.name          = "ssm-dokku"
  spec.version       = Ssm::Dokku::VERSION
  spec.authors       = ["Max Marze"]
  spec.email         = ["max@marze.io"]

  spec.summary       = %q{A Wrapper to use Dokku in AWS without exposing port 22 to traffic}
  spec.description   = %q{A Wrapper to use Dokku in AWS without exposing port 22 to traffic}
  spec.homepage      = "https://github.com/Mmarzex/ssm-dokku"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/Mmarzex/ssm-dokku"
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
