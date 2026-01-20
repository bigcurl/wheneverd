# frozen_string_literal: true

module Wheneverd
  module Trigger
    # A monotonic interval trigger for `systemd` timers.
    #
    # We emit both:
    # - `OnActiveSec=` to schedule the first run relative to timer activation.
    # - `OnUnitActiveSec=` to schedule subsequent runs relative to the last run.
    class Interval
      include Base

      # @return [Integer]
      attr_reader :seconds

      # @param seconds [Integer] seconds between runs (must be positive)
      def initialize(seconds:)
        @seconds = Validation.positive_integer(seconds, name: "Interval seconds")
      end

      # @return [Array<String>] systemd `[Timer]` lines for this trigger
      def systemd_timer_lines
        ["OnActiveSec=#{seconds}", "OnUnitActiveSec=#{seconds}"]
      end

      # @return [String] stable signature for unit naming
      def signature
        "interval:#{seconds}"
      end
    end
  end
end
