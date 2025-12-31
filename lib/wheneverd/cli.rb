# frozen_string_literal: true

require "clamp"
require_relative "../wheneverd"

module Wheneverd
  class CLI < Clamp::Command
    option ["-v", "--version"], :flag, "Print version"
    option "--verbose", :flag, "Verbose output"
    option "--schedule", "PATH", "Schedule file path", default: "config/schedule.rb"
    option "--identifier", "NAME", "Unit identifier (defaults to current directory name)"
    option "--unit-dir", "PATH", "systemd unit directory",
           default: Wheneverd::Systemd::UnitWriter::DEFAULT_UNIT_DIR

    def identifier_value
      identifier || File.basename(Dir.pwd)
    end

    def load_schedule
      path = File.expand_path(schedule)
      unless File.file?(path)
        raise Wheneverd::DSL::LoadError.new("Schedule file not found: #{path}", path: path)
      end

      Wheneverd::DSL::Loader.load_file(path)
    end

    def handle_error(error)
      warn error.message
      warn error.full_message if verbose?
      1
    end
  end
end

require_relative "cli/help"
require_relative "cli/init"
require_relative "cli/show"
require_relative "cli/write"
require_relative "cli/delete"

module Wheneverd
  class CLI
    self.default_subcommand = "help"

    subcommand "help", "Show help", Wheneverd::CLI::Help
    subcommand "init", "Create a schedule template", Wheneverd::CLI::Init
    subcommand "show", "Render units to stdout", Wheneverd::CLI::Show
    subcommand "write", "Write units to disk", Wheneverd::CLI::Write
    subcommand "delete", "Delete units from disk", Wheneverd::CLI::Delete
  end
end
