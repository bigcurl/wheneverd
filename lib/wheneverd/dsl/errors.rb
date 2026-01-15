# frozen_string_literal: true

module Wheneverd
  module DSL
    # Base error class for schedule DSL problems.
    #
    # These errors include the path to the schedule file to make CLI output more actionable.
    class Error < Wheneverd::Error
      # @return [String]
      attr_reader :path

      # @param message [String]
      # @param path [String]
      def initialize(message, path:)
        super(message)
        @path = path
      end
    end

    # Raised when a schedule file cannot be evaluated or is invalid.
    class LoadError < Error; end

    # Raised when an `every(...)` period cannot be parsed or validated.
    class InvalidPeriodError < Error; end

    # Raised when `at:` times cannot be validated.
    class InvalidAtError < Error; end
  end
end
