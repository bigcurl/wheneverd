# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd deactivate` (stop + disable timers/services via `systemctl --user`).
  class CLI::Deactivate < CLI
    def execute
      units = activatable_unit_basenames
      return 0 if units.empty?

      Wheneverd::Systemd::Systemctl.run("stop", *units)
      Wheneverd::Systemd::Systemctl.run("disable", *units)

      units.each { |unit| puts unit }
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end
