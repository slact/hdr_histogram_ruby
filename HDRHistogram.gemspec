# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'HDRHistogram/version'

Gem::Specification.new do |spec|
  spec.name          = "HDRHistogram"
  spec.version       = HDRHistogram::VERSION
  spec.authors       = ["Leo P."]
  spec.email         = ["junk@slact.net"]

  spec.summary       = "Ruby wrapper for the C hdr_histogram library"
  spec.description   = "HdrHistogram is an algorithm designed for recording histograms of value measurements with configurable precision. Value precision is expressed as the number of significant digits, providing control over value quantization and resolution whilst maintaining a fixed cost in both space and time."
  spec.homepage      = "https://github.com/slact/hdr_histogram_ruby"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.extensions = ["ext/ruby_hdr_histogram/extconf.rb"]
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-compiler"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-debundle"
end
