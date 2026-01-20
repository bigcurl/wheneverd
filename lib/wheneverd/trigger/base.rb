# frozen_string_literal: true

module Wheneverd
  module Trigger
    # Base module for trigger types.
    #
    # All trigger types must implement:
    # - `#systemd_timer_lines` - returns Array<String> of systemd [Timer] lines
    # - `#signature` - returns a String signature for stable unit naming
    module Base
      # @return [Array<String>] systemd `[Timer]` lines for this trigger
      def systemd_timer_lines
        raise NotImplementedError, "#{self.class} must implement #systemd_timer_lines"
      end

      # @return [String] stable signature for unit naming
      def signature
        raise NotImplementedError, "#{self.class} must implement #signature"
      end
    end
  end
end
