# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd status` (show installed timer status via `systemctl --user`).
  class CLI::Status < CLI
    def execute
      timer_units = installed_timer_unit_basenames
      return 0 if timer_units.empty?

      print_list_timers(timer_units)
      print_status(timer_units)
      0
    rescue StandardError => e
      handle_error(e)
    end

    private

    # @return [Array<String>]
    def installed_timer_unit_basenames
      paths = Wheneverd::Systemd::UnitLister.list(identifier: identifier_value, unit_dir: unit_dir)
      paths.map { |path| File.basename(path) }.grep(/\.timer\z/).uniq
    end

    def print_list_timers(timer_units)
      stdout, = Wheneverd::Systemd::Systemctl.run("list-timers", "--all", *timer_units)
      print stdout
    end

    def print_status(timer_units)
      timer_units.each do |unit|
        stdout, = Wheneverd::Systemd::Systemctl.run("status", unit)
        print stdout
      end
    end
  end
end
