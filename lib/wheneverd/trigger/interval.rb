# frozen_string_literal: true

module Wheneverd
  module Trigger
    # A monotonic interval trigger, rendered as `OnUnitActiveSec=`.
    class Interval
      # @return [Integer]
      attr_reader :seconds

      # @param seconds [Integer] seconds between runs (must be positive)
      def initialize(seconds:)
        unless seconds.is_a?(Integer)
          raise ArgumentError, "Interval seconds must be an Integer (got #{seconds.class})"
        end
        raise ArgumentError, "Interval seconds must be positive (got #{seconds})" if seconds <= 0

        @seconds = seconds
      end

      # @return [Array<String>] systemd `[Timer]` lines for this trigger
      def systemd_timer_lines
        ["OnUnitActiveSec=#{seconds}"]
      end
    end
  end
end
