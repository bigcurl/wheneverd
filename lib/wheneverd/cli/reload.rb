# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd reload` (write units, reload daemon, restart timers).
  class CLI::Reload < CLI
    def execute
      units = render_units
      paths = Wheneverd::Systemd::UnitWriter.write(units, unit_dir: unit_dir)
      timer_units = units.select { |unit| unit.kind == :timer }.map(&:path_basename).uniq
      return 0 if timer_units.empty?

      Wheneverd::Systemd::Systemctl.run("daemon-reload")
      Wheneverd::Systemd::Systemctl.run("restart", *timer_units)

      paths.each { |p| puts p }
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end
