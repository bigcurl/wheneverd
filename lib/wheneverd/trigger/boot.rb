# frozen_string_literal: true

module Wheneverd
  module Trigger
    # A boot trigger, rendered as `OnBootSec=`.
    class Boot
      # @return [Integer]
      attr_reader :seconds

      # @param seconds [Integer] seconds after boot (must be positive)
      def initialize(seconds:)
        unless seconds.is_a?(Integer)
          raise ArgumentError, "Boot seconds must be an Integer (got #{seconds.class})"
        end
        raise ArgumentError, "Boot seconds must be positive (got #{seconds})" if seconds <= 0

        @seconds = seconds
      end

      # @return [Array<String>] systemd `[Timer]` lines for this trigger
      def systemd_timer_lines
        ["OnBootSec=#{seconds}"]
      end
    end
  end
end
