# frozen_string_literal: true

module Wheneverd
  module Trigger
    class Calendar
      attr_reader :on_calendar

      def initialize(on_calendar:)
        unless on_calendar.is_a?(Array) && !on_calendar.empty? &&
               on_calendar.all? { |v| v.is_a?(String) && !v.strip.empty? }
          raise ArgumentError, "on_calendar must be a non-empty Array of non-empty Strings"
        end

        @on_calendar = on_calendar.map(&:strip)
      end

      def systemd_timer_lines
        on_calendar.map { |spec| "OnCalendar=#{spec}" }
      end
    end
  end
end
