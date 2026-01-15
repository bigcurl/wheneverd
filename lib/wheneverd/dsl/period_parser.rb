# frozen_string_literal: true

require_relative "calendar_symbol_period_list"

module Wheneverd
  module DSL
    # Converts DSL `every(...)` period values into trigger objects.
    #
    # Supported period forms are described in the README.
    #
    # Notes:
    #
    # - Interval strings and {Wheneverd::Duration} values produce monotonic triggers
    #   ({Wheneverd::Trigger::Interval}).
    # - Calendar symbol periods and cron strings produce calendar triggers
    #   ({Wheneverd::Trigger::Calendar}).
    # - The `at:` option is only valid for calendar triggers, with a convenience exception for
    #   `every 1.day, at: ...` which is treated as a daily calendar trigger.
    class PeriodParser
      DAY_SECONDS = 60 * 60 * 24
      REBOOT_NOT_SUPPORTED_MESSAGE =
        "The :reboot period is not supported; use an interval or calendar period instead"

      CALENDAR_SYMBOLS = %i[
        hour day month year weekday weekend
        monday tuesday wednesday thursday friday saturday sunday
      ].freeze

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
        trigger_for_period(period, at_times: at_times)
      rescue Wheneverd::InvalidIntervalError => e
        raise InvalidPeriodError.new(e.message, path: path)
      end

      private

      def trigger_for_period(period, at_times:)
        return duration_trigger_for(period, at_times: at_times) if period.is_a?(Wheneverd::Duration)
        return array_trigger_for(period, at_times: at_times) if period.is_a?(Array)
        return string_trigger_for(period, at_times: at_times) if period.is_a?(String)
        return symbol_trigger_for(period, at_times: at_times) if period.is_a?(Symbol)

        raise InvalidPeriodError.new("Unsupported period type: #{period.class}", path: path)
      end

      def duration_trigger_for(duration, at_times:)
        if at_times.any?
          return daily_calendar_trigger(at_times) if duration.to_i == DAY_SECONDS

          raise InvalidPeriodError.new("at: is only supported with calendar periods", path: path)
        end

        Wheneverd::Trigger::Interval.new(seconds: duration.to_i)
      end

      def daily_calendar_trigger(at_times)
        Wheneverd::Trigger::Calendar.new(on_calendar: build_calendar_specs("day", at_times))
      end

      def string_trigger_for(str, at_times:)
        period_str = str.strip

        return interval_trigger(period_str, at_times: at_times) if interval_string?(period_str)

        return cron_trigger(period_str, at_times: at_times) if cron_string?(period_str)

        raise InvalidPeriodError.new("Unrecognized period #{period_str.inspect}", path: path)
      end

      def interval_trigger(period_str, at_times:)
        if at_times.any?
          raise InvalidPeriodError.new("at: is not supported for interval periods", path: path)
        end

        seconds = Wheneverd::Interval.parse(period_str)
        Wheneverd::Trigger::Interval.new(seconds: seconds)
      end

      def cron_trigger(period_str, at_times:)
        if at_times.any?
          raise InvalidPeriodError.new("at: is not supported for cron periods", path: path)
        end

        Wheneverd::Trigger::Calendar.new(on_calendar: ["cron:#{period_str}"])
      end

      def symbol_trigger_for(sym, at_times:)
        raise InvalidPeriodError.new(REBOOT_NOT_SUPPORTED_MESSAGE, path: path) if sym == :reboot

        if CALENDAR_SYMBOLS.include?(sym)
          return Wheneverd::Trigger::Calendar.new(
            on_calendar: build_calendar_specs(sym.to_s, at_times)
          )
        end

        raise InvalidPeriodError.new("Unknown period symbol: #{sym.inspect}", path: path)
      end

      def array_trigger_for(periods, at_times:)
        bases = CalendarSymbolPeriodList.validate(
          periods,
          allowed_symbols: CALENDAR_SYMBOLS,
          path: path
        ).map(&:to_s)
        specs = bases.flat_map { |base| build_calendar_specs(base, at_times) }.uniq
        Wheneverd::Trigger::Calendar.new(on_calendar: specs)
      end

      def build_calendar_specs(base, at_times)
        return [base] if at_times.empty?

        at_times.map { |t| "#{base}@#{t}" }
      end

      def interval_string?(str)
        /\A-?\d+[smhdw]\z/.match?(str)
      end

      def cron_string?(str)
        str.split(/\s+/).length == 5
      end
    end
  end
end
