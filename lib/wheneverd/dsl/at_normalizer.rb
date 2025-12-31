# frozen_string_literal: true

module Wheneverd
  module DSL
    module AtNormalizer
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
