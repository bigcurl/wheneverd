# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd activate` (enable + start timers/services via `systemctl --user`).
  class CLI::Activate < CLI
    def execute
      units = activatable_unit_basenames
      return 0 if units.empty?

      Wheneverd::Systemd::Systemctl.run("daemon-reload")
      Wheneverd::Systemd::Systemctl.run("enable", "--now", *units)

      units.each { |unit| puts unit }
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end
