# frozen_string_literal: true

module Wheneverd
  # Base error class for wheneverd exceptions.
  class Error < StandardError; end

  # Raised when {Wheneverd::Interval.parse} cannot parse or validate an interval string.
  class InvalidIntervalError < Error; end

  # Raised when a {Wheneverd::Job::Command} is created with an invalid command string.
  class InvalidCommandError < Error; end
end
