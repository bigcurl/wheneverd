# frozen_string_literal: true

module Wheneverd
  class CLI::Write < CLI
    option "--dry-run", :flag, "Print paths only; do not write"

    def execute
      schedule_obj = load_schedule
      units = Wheneverd::Systemd::Renderer.render(schedule_obj, identifier: identifier_value)
      paths = Wheneverd::Systemd::UnitWriter.write(units, unit_dir: unit_dir, dry_run: dry_run?)
      paths.each { |p| puts p }
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end
