# frozen_string_literal: true

require "clamp"
require_relative "../wheneverd"

module Wheneverd
  # Command-line interface for `wheneverd`.
  #
  # This class defines global options and shared helpers used by each subcommand.
  class CLI < Clamp::Command
    option ["-v", "--version"], :flag, "Print version"
    option "--verbose", :flag, "Verbose output"
    option "--schedule", "PATH", "Schedule file path", default: "config/schedule.rb"
    option "--identifier", "NAME", "Unit identifier (defaults to current directory name)"
    option "--unit-dir", "PATH", "systemd unit directory",
           default: Wheneverd::Systemd::UnitWriter::DEFAULT_UNIT_DIR

    # @return [String] the identifier used for unit file names
    def identifier_value
      identifier || File.basename(Dir.pwd)
    end

    # Load the configured schedule file.
    #
    # @return [Wheneverd::Schedule]
    def load_schedule
      path = File.expand_path(schedule)
      unless File.file?(path)
        raise Wheneverd::DSL::LoadError.new("Schedule file not found: #{path}", path: path)
      end

      Wheneverd::DSL::Loader.load_file(path)
    end

    # Print an error message and return a non-zero exit status.
    #
    # @param error [Exception]
    # @return [Integer]
    def handle_error(error)
      warn error.message
      warn error.full_message if verbose?
      1
    end

    # Render schedule units for this invocation.
    #
    # @return [Array<Wheneverd::Systemd::Unit>]
    def render_units
      schedule_obj = load_schedule
      Wheneverd::Systemd::Renderer.render(schedule_obj, identifier: identifier_value)
    end

    # @param units [Array<Wheneverd::Systemd::Unit>]
    # @return [Array<String>] timer unit basenames
    def timer_unit_basenames(units = render_units)
      units.select { |unit| unit.kind == :timer }.map(&:path_basename).uniq
    end

    private :render_units, :timer_unit_basenames
  end
end

require_relative "cli/help"
require_relative "cli/init"
require_relative "cli/show"
require_relative "cli/validate"
require_relative "cli/write"
require_relative "cli/delete"
require_relative "cli/activate"
require_relative "cli/deactivate"
require_relative "cli/reload"
require_relative "cli/current"
require_relative "cli/linger"

module Wheneverd
  class CLI
    self.default_subcommand = "help"

    subcommand "help", "Show help", Wheneverd::CLI::Help
    subcommand "init", "Create a schedule template", Wheneverd::CLI::Init
    subcommand "show", "Render units to stdout", Wheneverd::CLI::Show
    subcommand "validate", "Validate schedule via systemd-analyze", Wheneverd::CLI::Validate
    subcommand "write", "Write units to disk", Wheneverd::CLI::Write
    subcommand "delete", "Delete units from disk", Wheneverd::CLI::Delete
    subcommand "activate", "Enable and start timers via systemctl --user", Wheneverd::CLI::Activate
    subcommand "deactivate", "Stop and disable timers via systemctl --user", Wheneverd::CLI::Deactivate
    subcommand "reload", "Write units, reload daemon, restart timers", Wheneverd::CLI::Reload
    subcommand "current", "Show installed units from disk", Wheneverd::CLI::Current
    subcommand "linger", "Manage systemd user lingering via loginctl", Wheneverd::CLI::Linger
  end
end
