# frozen_string_literal: true

module Wheneverd
  module Systemd
    # Base error class for systemd rendering and system interactions.
    class Error < Wheneverd::Error; end

    # Raised when an identifier is invalid for use in unit file names.
    class InvalidIdentifierError < Error; end

    # Raised when a human-friendly time string cannot be parsed.
    class InvalidTimeError < Error; end

    # Raised when a calendar spec cannot be mapped to a valid `OnCalendar=` value.
    class InvalidCalendarSpecError < Error; end

    # Raised when the provided cron expression is outside the supported subset.
    class UnsupportedCronError < Error; end

    # Raised when a `systemctl` invocation fails.
    class SystemctlError < Error; end
  end
end
