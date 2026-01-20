# frozen_string_literal: true

module Wheneverd
  module Trigger
    # A calendar trigger, rendered as one or more `OnCalendar=` lines.
    class Calendar
      include Base

      # @return [Array<String>] calendar specs (already in `systemd` OnCalendar format)
      attr_reader :on_calendar

      # @param on_calendar [Array<String>] non-empty calendar specs
      def initialize(on_calendar:)
        unless on_calendar.is_a?(Array) && !on_calendar.empty? &&
               on_calendar.all? { |v| v.is_a?(String) && !v.strip.empty? }
          raise ArgumentError, "on_calendar must be a non-empty Array of non-empty Strings"
        end

        @on_calendar = on_calendar.map(&:strip)
      end

      # @return [Array<String>] systemd `[Timer]` lines for this trigger
      def systemd_timer_lines
        on_calendar.map { |spec| "OnCalendar=#{spec}" }
      end

      # @return [String] stable signature for unit naming
      def signature
        "calendar:#{on_calendar.sort.join('|')}"
      end
    end
  end
end
