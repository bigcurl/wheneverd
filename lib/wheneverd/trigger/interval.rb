# frozen_string_literal: true

module Wheneverd
  module Trigger
    class Interval
      attr_reader :seconds

      def initialize(seconds:)
        unless seconds.is_a?(Integer)
          raise ArgumentError, "Interval seconds must be an Integer (got #{seconds.class})"
        end
        raise ArgumentError, "Interval seconds must be positive (got #{seconds})" if seconds <= 0

        @seconds = seconds
      end

      def systemd_timer_lines
        ["OnUnitActiveSec=#{seconds}"]
      end
    end
  end
end
