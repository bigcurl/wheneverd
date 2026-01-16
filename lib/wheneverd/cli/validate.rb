# frozen_string_literal: true

require "tmpdir"

module Wheneverd
  # Implements `wheneverd validate` (validate rendered OnCalendar values and unit files).
  class CLI::Validate < CLI
    option "--verify", :flag,
           "Also run systemd-analyze --user verify (writes units to a temporary directory)"

    def execute
      units = render_units
      validate_on_calendar(units)
      validate_units(units) if verify?
      0
    rescue StandardError => e
      handle_error(e)
    end

    private

    def validate_on_calendar(units)
      values = on_calendar_values(units)
      if values.empty?
        puts "No OnCalendar= values found" if verbose?
        return
      end

      values.each do |value|
        Wheneverd::Systemd::Analyze.calendar(value)
        puts "OK OnCalendar=#{value}" if verbose?
      end
    end

    def on_calendar_values(units)
      units.select { |unit| unit.kind == :timer }
           .flat_map { |timer| timer.contents.to_s.lines.grep(/\AOnCalendar=/) }
           .map { |line| line.delete_prefix("OnCalendar=").strip }
           .uniq
    end

    def validate_units(units)
      Dir.mktmpdir("wheneverd-validate-") do |dir|
        paths = Wheneverd::Systemd::UnitWriter.write(units, unit_dir: dir, prune: false)
        Wheneverd::Systemd::Analyze.verify(paths, user: true)
        puts "OK systemd-analyze --user verify" if verbose?
      end
    end
  end
end
