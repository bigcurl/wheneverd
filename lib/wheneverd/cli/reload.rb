# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd reload` (write units, reload daemon, restart timers/services).
  class CLI::Reload < CLI
    option "--[no-]prune", :flag,
           "Prune previously generated units for the identifier (default: enabled)",
           default: true

    def execute
      paths, units = write_units_and_activatable_basenames
      return 0 if units.empty?

      reload_systemd(units)

      paths.each { |path| puts path }
      0
    rescue StandardError => e
      handle_error(e)
    end

    private

    def write_units_and_activatable_basenames
      units = render_units
      paths = Wheneverd::Systemd::UnitWriter.write(
        units,
        unit_dir: unit_dir,
        prune: prune?,
        identifier: identifier_value
      )
      [paths, activatable_unit_basenames(units)]
    end

    def reload_systemd(units)
      Wheneverd::Systemd::Systemctl.run("daemon-reload")
      Wheneverd::Systemd::Systemctl.run("restart", *units)
    end
  end
end
