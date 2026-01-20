# frozen_string_literal: true

module Wheneverd
  module DSL
    module PeriodStrategy
      # Strategy for parsing String period values.
      #
      # Handles interval strings (e.g., "5m", "1h") and cron expressions.
      class StringStrategy < Base
        INTERVAL_PATTERN = /\A-?\d+[smhdw]\z/

        def handles?(period)
          period.is_a?(String)
        end

        def parse(str, at_times:)
          period_str = str.strip

          return parse_interval(period_str, at_times: at_times) if interval_string?(period_str)

          return parse_cron(period_str, at_times: at_times) if cron_string?(period_str)

          raise_period_error("Unrecognized period #{period_str.inspect}")
        end

        private

        def parse_interval(period_str, at_times:)
          if at_times.any?
            raise_period_error("at: is not supported for interval periods")
          end

          seconds = Wheneverd::Interval.parse(period_str)
          interval_trigger(seconds: seconds)
        end

        def parse_cron(period_str, at_times:)
          if at_times.any?
            raise_period_error("at: is not supported for cron periods")
          end

          calendar_trigger(on_calendar: ["cron:#{period_str}"])
        end

        def interval_string?(str)
          INTERVAL_PATTERN.match?(str)
        end

        def cron_string?(str)
          str.split(/\s+/).length == 5
        end
      end
    end
  end
end
