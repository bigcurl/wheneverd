# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd deactivate` (stop + disable timers via `systemctl --user`).
  class CLI::Deactivate < CLI
    def execute
      timer_units = timer_unit_basenames
      return 0 if timer_units.empty?

      Wheneverd::Systemd::Systemctl.run("stop", *timer_units)
      Wheneverd::Systemd::Systemctl.run("disable", *timer_units)

      timer_units.each { |unit| puts unit }
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end
