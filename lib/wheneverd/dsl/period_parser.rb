# frozen_string_literal: true

module Wheneverd
  module DSL
    class PeriodParser
      DAY_SECONDS = 60 * 60 * 24
      DEFAULT_REBOOT_SECONDS = 60

      CALENDAR_SYMBOLS = %i[
        hour
        day
        month
        year
        weekday
        weekend
        monday
        tuesday
        wednesday
        thursday
        friday
        saturday
        sunday
      ].freeze

      attr_reader :path

      def initialize(path:)
        @path = path
      end

      def trigger_for(period, at:)
        at_times = AtNormalizer.normalize(at, path: path)
        trigger_for_period(period, at_times: at_times)
      rescue Wheneverd::InvalidIntervalError => e
        raise InvalidPeriodError.new(e.message, path: path)
      end

      private

      def trigger_for_period(period, at_times:)
        case period
        when Wheneverd::Duration
          duration_trigger_for(period, at_times: at_times)
        when String
          string_trigger_for(period, at_times: at_times)
        when Symbol
          symbol_trigger_for(period, at_times: at_times)
        else
          raise InvalidPeriodError.new("Unsupported period type: #{period.class}", path: path)
        end
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
        return reboot_trigger(at_times) if sym == :reboot

        if CALENDAR_SYMBOLS.include?(sym)
          return Wheneverd::Trigger::Calendar.new(
            on_calendar: build_calendar_specs(sym.to_s, at_times)
          )
        end

        raise InvalidPeriodError.new("Unknown period symbol: #{sym.inspect}", path: path)
      end

      def reboot_trigger(at_times)
        if at_times.any?
          raise InvalidPeriodError.new("at: is not supported for :reboot", path: path)
        end

        Wheneverd::Trigger::Boot.new(seconds: DEFAULT_REBOOT_SECONDS)
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
