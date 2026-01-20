# frozen_string_literal: true

require_relative "period_strategy"

module Wheneverd
  module DSL
    # Converts DSL `every(...)` period values into trigger objects.
    #
    # Supported period forms are described in the README.
    #
    # Uses a strategy pattern to delegate parsing to specialized strategy classes:
    # - {PeriodStrategy::DurationStrategy} for Duration values
    # - {PeriodStrategy::StringStrategy} for interval strings and cron expressions
    # - {PeriodStrategy::SymbolStrategy} for calendar symbols
    # - {PeriodStrategy::ArrayStrategy} for arrays of calendar symbols
    class PeriodParser
      attr_reader :path

      # @param path [String] schedule path for error reporting
      def initialize(path:)
        @path = path
      end

      # @param period [String, Symbol, Array<Symbol>, Wheneverd::Duration]
      # @param at [String, Array<String>, nil]
      # @return [Wheneverd::Trigger::Interval, Wheneverd::Trigger::Calendar]
      def trigger_for(period, at:)
        at_times = AtNormalizer.normalize(at, path: path)
        strategy = PeriodStrategy.for(period, path: path)
        strategy.parse(period, at_times: at_times)
      rescue Wheneverd::InvalidIntervalError => e
        raise InvalidPeriodError.new(e.message, path: path)
      end
    end
  end
end
