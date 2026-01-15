# frozen_string_literal: true

require_relative "lib/wheneverd/version"

Gem::Specification.new do |spec|
  spec.name = "wheneverd"
  spec.version = Wheneverd::VERSION
  spec.authors = ["bigcurl"]

  spec.summary = "Wheneverd is to systemd timers what whenever is to cron."
  spec.description =
    "Generates systemd timer/service units from a Ruby DSL, similar in spirit " \
    "to the whenever gem for cron."
  spec.homepage = "https://github.com/bigcurl/wheneverd"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files =
    begin
      Dir.chdir(__dir__) { `git ls-files -z`.split("\x0").reject(&:empty?) }
    rescue StandardError
      Dir.glob("{bin,exe,lib,test}/**/*", File::FNM_DOTMATCH).reject { |f| File.directory?(f) }
    end

  spec.bindir = "exe"
  spec.executables = ["wheneverd"]
  spec.require_paths = ["lib"]

  spec.add_dependency "clamp", "~> 1.3"
end
