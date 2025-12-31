# frozen_string_literal: true

module Wheneverd
  class CLI::Show < CLI
    def execute
      schedule_obj = load_schedule
      units = Wheneverd::Systemd::Renderer.render(schedule_obj, identifier: identifier_value)
      print_units(units)
      0
    rescue StandardError => e
      handle_error(e)
    end

    def print_units(units)
      units.each_with_index do |unit, idx|
        puts "# #{unit.path_basename}"
        puts unit.contents
        puts "" if idx < units.length - 1
      end
    end
  end
end
