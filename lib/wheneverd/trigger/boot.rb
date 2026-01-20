# frozen_string_literal: true

module Wheneverd
  module Trigger
    # A boot trigger, rendered as `OnBootSec=`.
    class Boot
      include Base

      # @return [Integer]
      attr_reader :seconds

      # @param seconds [Integer] seconds after boot (must be positive)
      def initialize(seconds:)
        @seconds = Validation.positive_integer(seconds, name: "Boot seconds")
      end

      # @return [Array<String>] systemd `[Timer]` lines for this trigger
      def systemd_timer_lines
        ["OnBootSec=#{seconds}"]
      end

      # @return [String] stable signature for unit naming
      def signature
        "boot:#{seconds}"
      end
    end
  end
end
