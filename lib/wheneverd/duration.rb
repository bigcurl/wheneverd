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
      @seconds = Validation.positive_integer(seconds, name: "Duration seconds")
    end

    def to_i
      seconds
    end
  end
end
