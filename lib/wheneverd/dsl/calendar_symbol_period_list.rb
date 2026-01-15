# frozen_string_literal: true

module Wheneverd
  module DSL
    # Validates `every(:monday, :tuesday, ...)` symbol lists.
    module CalendarSymbolPeriodList
      # @param periods [Array<Symbol>]
      # @param allowed_symbols [Array<Symbol>]
      # @param path [String]
      # @return [Array<Symbol>] the validated input
      def self.validate(periods, allowed_symbols:, path:)
        validate_array!(periods, path: path)
        validate_symbols!(periods, path: path)
        validate_allowed_symbols!(periods, allowed_symbols: allowed_symbols, path: path)
        periods
      end

      def self.validate_array!(periods, path:)
        return if periods.is_a?(Array) && !periods.empty?

        raise InvalidPeriodError.new("every() periods must be a non-empty Array", path: path)
      end
      private_class_method :validate_array!

      def self.validate_symbols!(periods, path:)
        return if periods.all?(Symbol)

        raise InvalidPeriodError.new("every() periods must be Symbols", path: path)
      end
      private_class_method :validate_symbols!

      def self.validate_allowed_symbols!(periods, allowed_symbols:, path:)
        invalid = periods.reject { |sym| allowed_symbols.include?(sym) }.uniq
        return if invalid.empty?

        unknown = invalid.map(&:inspect).join(", ")
        raise InvalidPeriodError.new("Unknown period symbol(s): #{unknown}", path: path)
      end
      private_class_method :validate_allowed_symbols!
    end
  end
end
