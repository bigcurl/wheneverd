# frozen_string_literal: true

module Wheneverd
  # Common validation utilities for consistent error handling across the codebase.
  #
  # These validators follow a consistent pattern:
  # - Return the validated value if valid
  # - Raise an appropriate error with a descriptive message if invalid
  #
  # @example Type validation
  #   Validation.type(value, Integer, name: "seconds")
  #   # => value or raises ArgumentError
  #
  # @example Positive integer validation
  #   Validation.positive_integer(value, name: "seconds")
  #   # => value or raises ArgumentError
  module Validation
    # Validate that a value is of the expected type.
    #
    # @param value [Object] the value to validate
    # @param expected_type [Class, Module] the expected type
    # @param name [String] the parameter name for error messages
    # @return [Object] the validated value
    # @raise [ArgumentError] if the value is not of the expected type
    def self.type(value, expected_type, name:)
      return value if value.is_a?(expected_type)

      raise ArgumentError, "#{name} must be #{expected_type_name(expected_type)} (got #{value.class})"
    end

    # Validate that a value is a positive integer.
    #
    # @param value [Object] the value to validate
    # @param name [String] the parameter name for error messages
    # @return [Integer] the validated value
    # @raise [ArgumentError] if the value is not a positive integer
    def self.positive_integer(value, name:)
      type(value, Integer, name: name)
      return value if value.positive?

      raise ArgumentError, "#{name} must be positive (got #{value})"
    end

    # Validate that a string is non-empty after stripping whitespace.
    #
    # @param value [String] the value to validate
    # @param name [String] the parameter name for error messages
    # @return [String] the stripped value
    # @raise [ArgumentError] if the value is empty after stripping
    def self.non_empty_string(value, name:)
      stripped = value.to_s.strip
      return stripped unless stripped.empty?

      raise ArgumentError, "#{name} must not be empty"
    end

    # Validate that an array is non-empty.
    #
    # @param value [Array] the value to validate
    # @param name [String] the parameter name for error messages
    # @return [Array] the validated value
    # @raise [ArgumentError] if the array is empty
    def self.non_empty_array(value, name:)
      type(value, Array, name: name)
      return value unless value.empty?

      raise ArgumentError, "#{name} must not be empty"
    end

    # Validate that a value is within a range.
    #
    # @param value [Comparable] the value to validate
    # @param range [Range] the valid range
    # @param name [String] the parameter name for error messages
    # @return [Comparable] the validated value
    # @raise [ArgumentError] if the value is outside the range
    def self.in_range(value, range, name:)
      return value if range.cover?(value)

      raise ArgumentError, "#{name} must be in #{range} (got #{value})"
    end

    def self.expected_type_name(expected_type)
      "a #{expected_type}"
    end
    private_class_method :expected_type_name
  end
end
