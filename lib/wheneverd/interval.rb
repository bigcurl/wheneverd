# frozen_string_literal: true

module Wheneverd
  # Parser for compact interval strings used by the DSL.
  #
  # The supported format is `"<n>s|m|h|d|w"`, for example `"5m"` or `"1h"`.
  module Interval
    MULTIPLIERS = {
      "s" => 1,
      "m" => 60,
      "h" => 60 * 60,
      "d" => 60 * 60 * 24,
      "w" => 60 * 60 * 24 * 7
    }.freeze

    FORMAT = /\A(?<n>-?\d+)(?<unit>[smhdw])\z/.freeze

    # Parse an interval string into seconds.
    #
    # @param str [String] interval like `"5m"`
    # @return [Integer] seconds
    # @raise [Wheneverd::InvalidIntervalError] if the input is invalid
    def self.parse(str)
      input = normalize_input(str)
      match = parse_match(input)
      n = parse_number(match[:n], input)
      n * MULTIPLIERS.fetch(match[:unit])
    end

    def self.normalize_input(str)
      str.to_s.strip
    end
    private_class_method :normalize_input

    def self.parse_match(input)
      match = FORMAT.match(input)
      return match if match

      raise InvalidIntervalError,
            "Invalid interval #{input.inspect}; expected <n>s|m|h|d|w (example: \"5m\")"
    end
    private_class_method :parse_match

    def self.parse_number(number_str, input)
      n = Integer(number_str, 10)
      raise InvalidIntervalError, "Interval must be positive (got #{input.inspect})" if n <= 0

      n
    end
    private_class_method :parse_number
  end
end
