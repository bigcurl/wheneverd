# frozen_string_literal: true

require_relative "../calendar_symbol_period_list"

module Wheneverd
  module DSL
    module PeriodStrategy
      # Strategy for parsing Array period values.
      #
      # Handles arrays of calendar symbols like [:monday, :wednesday, :friday].
      class ArrayStrategy < Base
        def handles?(period)
          period.is_a?(Array)
        end

        def parse(periods, at_times:)
          bases = CalendarSymbolPeriodList.validate(
            periods,
            allowed_symbols: CALENDAR_SYMBOLS,
            path: path
          ).map(&:to_s)

          specs = bases.flat_map { |base| build_calendar_specs(base, at_times) }.uniq
          calendar_trigger(on_calendar: specs)
        end
      end
    end
  end
end
