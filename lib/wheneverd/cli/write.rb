# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd write` (write rendered units to disk).
  class CLI::Write < CLI
    option "--dry-run", :flag, "Print paths only; do not write"
    option "--[no-]prune", :flag,
           "Prune previously generated units for the identifier (default: enabled)",
           default: true

    def execute
      write_paths.each { |path| puts path }
      0
    rescue StandardError => e
      handle_error(e)
    end

    private

    def write_paths
      schedule_obj = load_schedule
      units = Wheneverd::Systemd::Renderer.render(schedule_obj, identifier: identifier_value)
      Wheneverd::Systemd::UnitWriter.write(
        units,
        unit_dir: unit_dir,
        dry_run: dry_run?,
        prune: prune?,
        identifier: identifier_value
      )
    end
  end
end
