# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  add_filter "/test/"
  minimum_coverage ENV.fetch("MINIMUM_COVERAGE", "100").to_i
end

require "minitest/autorun"
require "wheneverd"
