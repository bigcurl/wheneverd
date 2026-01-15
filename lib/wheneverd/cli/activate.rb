# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd activate` (enable + start timers via `systemctl --user`).
  class CLI::Activate < CLI
    def execute
      timer_units = timer_unit_basenames
      return 0 if timer_units.empty?

      Wheneverd::Systemd::Systemctl.run("daemon-reload")
      Wheneverd::Systemd::Systemctl.run("enable", "--now", *timer_units)

      timer_units.each { |unit| puts unit }
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end
