# frozen_string_literal: true

require_relative "period_strategy/base"
require_relative "period_strategy/duration_strategy"
require_relative "period_strategy/string_strategy"
require_relative "period_strategy/symbol_strategy"
require_relative "period_strategy/array_strategy"

module Wheneverd
  module DSL
    # Period parsing strategies for converting DSL period values into triggers.
    #
    # Each strategy handles a specific type of period value and converts it
    # into the appropriate trigger type.
    module PeriodStrategy
      # Default strategies in order of precedence.
      DEFAULT_STRATEGIES = [
        DurationStrategy,
        ArrayStrategy,
        StringStrategy,
        SymbolStrategy
      ].freeze

      # Find the strategy that handles the given period type.
      #
      # @param period [Object] the period value
      # @param path [String] schedule path for error reporting
      # @return [Base] the strategy instance
      # @raise [Wheneverd::DSL::InvalidPeriodError] if no strategy handles the period
      def self.for(period, path:)
        strategy_class = DEFAULT_STRATEGIES.find do |klass|
          klass.new(path: path).handles?(period)
        end

        if strategy_class.nil?
          raise InvalidPeriodError.new("Unsupported period type: #{period.class}", path: path)
        end

        strategy_class.new(path: path)
      end
    end
  end
end
