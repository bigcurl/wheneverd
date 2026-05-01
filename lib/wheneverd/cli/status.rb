# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd status` (show installed timer/service status via `systemctl --user`).
  class CLI::Status < CLI
    def execute
      timer_units, service_units = installed_unit_basenames
      units = timer_units + service_units
      return 0 if units.empty?

      print_list_timers(timer_units)
      print_status(units)
      0
    rescue StandardError => e
      handle_error(e)
    end

    private

    # @return [Array<String>]
    def installed_unit_basenames
      paths = Wheneverd::Systemd::UnitLister.list(identifier: identifier_value, unit_dir: unit_dir)
      basenames = paths.map { |path| File.basename(path) }
      timers = basenames.grep(/\.timer\z/).uniq
      timer_managed_services = timers.map { |timer| timer.sub(/\.timer\z/, ".service") }
      services = basenames.grep(/\.service\z/).uniq - timer_managed_services
      [timers, services]
    end

    def print_list_timers(timer_units)
      return if timer_units.empty?

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
