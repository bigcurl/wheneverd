# frozen_string_literal: true

module Wheneverd
  module DSL
    module PeriodStrategy
      # Strategy for parsing Symbol period values.
      #
      # Handles calendar symbols like :day, :monday, :weekend, etc.
      class SymbolStrategy < Base
        REBOOT_NOT_SUPPORTED_MESSAGE =
          "The :reboot period is not supported; use an interval or calendar period instead"

        def handles?(period)
          period.is_a?(Symbol)
        end

        def parse(sym, at_times:)
          raise_period_error(REBOOT_NOT_SUPPORTED_MESSAGE) if sym == :reboot

          if CALENDAR_SYMBOLS.include?(sym)
            return calendar_trigger(
              on_calendar: build_calendar_specs(sym.to_s, at_times)
            )
          end

          raise_period_error("Unknown period symbol: #{sym.inspect}")
        end
      end
    end
  end
end
