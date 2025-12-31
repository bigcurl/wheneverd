# frozen_string_literal: true

module Wheneverd
  module Interval
    MULTIPLIERS = {
      "s" => 1,
      "m" => 60,
      "h" => 60 * 60,
      "d" => 60 * 60 * 24,
      "w" => 60 * 60 * 24 * 7
    }.freeze

    FORMAT = /\A(?<n>-?\d+)(?<unit>[smhdw])\z/.freeze

    def self.parse(str)
      input = str.to_s.strip
      match = FORMAT.match(input)
      unless match
        raise InvalidIntervalError,
              "Invalid interval #{input.inspect}; expected <n>s|m|h|d|w (example: \"5m\")"
      end

      n = Integer(match[:n], 10)
      raise InvalidIntervalError, "Interval must be positive (got #{input.inspect})" if n <= 0

      n * MULTIPLIERS.fetch(match[:unit])
    end
  end
end
