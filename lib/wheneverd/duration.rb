# frozen_string_literal: true

module Wheneverd
  # A positive duration represented as a whole number of seconds.
  #
  # This type is produced by the `Numeric` helpers from {Wheneverd::CoreExt::NumericDuration}
  # (for example, `5.minutes`), and is used by the DSL period parser.
  class Duration
    # @return [Integer] duration in seconds
    attr_reader :seconds

    # @param seconds [Integer] duration in seconds (must be positive)
    def initialize(seconds)
      unless seconds.is_a?(Integer)
        raise ArgumentError, "Duration seconds must be an Integer (got #{seconds.class})"
      end

      raise ArgumentError, "Duration seconds must be positive (got #{seconds})" if seconds <= 0

      @seconds = seconds
    end

    def to_i
      seconds
    end
  end
end
