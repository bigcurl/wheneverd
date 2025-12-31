# frozen_string_literal: true

module Wheneverd
  class Duration
    attr_reader :seconds

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
