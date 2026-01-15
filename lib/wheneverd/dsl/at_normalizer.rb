# frozen_string_literal: true

module Wheneverd
  module DSL
    # Validates and normalizes the `at:` option from the schedule DSL.
    #
    # `at:` can be a single string (e.g. `"4:30 am"`) or an array of strings (multiple run times).
    module AtNormalizer
      # @param at [String, Array<String>, nil]
      # @param path [String] schedule path for error reporting
      # @return [Array<String>] normalized time strings (not parsed)
      def self.normalize(at, path:)
        return [] if at.nil?

        return [normalize_string(at, path: path)] if at.is_a?(String)

        return normalize_array(at, path: path) if at.is_a?(Array)

        raise InvalidAtError.new("at: must be a String or an Array of Strings", path: path)
      end

      def self.normalize_string(value, path:)
        at_str = value.strip
        raise InvalidAtError.new("at: must not be empty", path: path) if at_str.empty?

        at_str
      end
      private_class_method :normalize_string

      def self.normalize_array(values, path:)
        times = values.map do |v|
          unless v.is_a?(String)
            raise InvalidAtError.new("at: must be a String or an Array of Strings", path: path)
          end

          v.strip
        end

        if times.empty? || times.any?(&:empty?)
          raise InvalidAtError.new("at: must not be empty", path: path)
        end

        times
      end
      private_class_method :normalize_array
    end
  end
end
