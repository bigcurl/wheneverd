# frozen_string_literal: true

module Wheneverd
  module DSL
    module PeriodStrategy
      # Base class for period parsing strategies.
      #
      # Each strategy handles a specific type of period value (Duration, String, Symbol, Array)
      # and converts it into a trigger object.
      class Base
        DAY_SECONDS = 60 * 60 * 24

        CALENDAR_SYMBOLS = %i[
          hour day month year weekday weekend
          monday tuesday wednesday thursday friday saturday sunday
        ].freeze

        attr_reader :path

        # @param path [String] schedule path for error reporting
        def initialize(path:)
          @path = path
        end

        # Check if this strategy handles the given period type.
        #
        # @param period [Object] the period value
        # @return [Boolean]
        def handles?(_period)
          raise NotImplementedError, "#{self.class} must implement #handles?"
        end

        # Parse the period into a trigger.
        #
        # @param period [Object] the period value
        # @param at_times [Array<String>] normalized at: times
        # @return [Wheneverd::Trigger::Interval, Wheneverd::Trigger::Calendar]
        # @raise [Wheneverd::DSL::InvalidPeriodError]
        def parse(_period, at_times:)
          raise NotImplementedError, "#{self.class} must implement #parse"
        end

        protected

        def raise_period_error(message)
          raise InvalidPeriodError.new(message, path: path)
        end

        def build_calendar_specs(base, at_times)
          return [base] if at_times.empty?

          at_times.map { |t| "#{base}@#{t}" }
        end

        def calendar_trigger(on_calendar:)
          Wheneverd::Trigger::Calendar.new(on_calendar: on_calendar)
        end

        def interval_trigger(seconds:)
          Wheneverd::Trigger::Interval.new(seconds: seconds)
        end
      end
    end
  end
end
