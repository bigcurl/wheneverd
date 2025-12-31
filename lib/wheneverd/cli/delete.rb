# frozen_string_literal: true

module Wheneverd
  class CLI::Delete < CLI
    option "--dry-run", :flag, "Print paths only; do not delete"

    def execute
      paths = Wheneverd::Systemd::UnitDeleter.delete(
        identifier: identifier_value,
        unit_dir: unit_dir,
        dry_run: dry_run?
      )
      paths.each { |p| puts p }
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end
