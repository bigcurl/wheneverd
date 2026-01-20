# frozen_string_literal: true

module Wheneverd
  module DSL
    module PeriodStrategy
      # Strategy for parsing Duration period values.
      #
      # Duration values produce Interval triggers, except for 1.day with at: times
      # which produces a Calendar trigger for daily scheduling.
      class DurationStrategy < Base
        def handles?(period)
          period.is_a?(Wheneverd::Duration)
        end

        def parse(duration, at_times:)
          if at_times.any?
            return daily_calendar_trigger(at_times) if duration.to_i == DAY_SECONDS

            raise_period_error("at: is only supported with calendar periods")
          end

          interval_trigger(seconds: duration.to_i)
        end

        private

        def daily_calendar_trigger(at_times)
          calendar_trigger(on_calendar: build_calendar_specs("day", at_times))
        end
      end
    end
  end
end
