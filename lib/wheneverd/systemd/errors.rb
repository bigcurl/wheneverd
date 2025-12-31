# frozen_string_literal: true

module Wheneverd
  module Systemd
    class Error < Wheneverd::Error; end

    class InvalidIdentifierError < Error; end
    class InvalidTimeError < Error; end
    class InvalidCalendarSpecError < Error; end
    class UnsupportedCronError < Error; end
  end
end
