# frozen_string_literal: true

module Wheneverd
  module DSL
    # The evaluation context used for schedule files.
    #
    # The schedule file is evaluated via `instance_eval`, so methods defined here become available
    # as the schedule DSL (`every`, `command`, `shell`).
    class Context
      # @return [String] absolute schedule path
      attr_reader :path

      # @return [Wheneverd::Schedule] schedule being built during evaluation
      attr_reader :schedule

      # @param path [String]
      def initialize(path:)
        @path = path
        @schedule = Wheneverd::Schedule.new
        @current_entry = nil
        @period_parser = Wheneverd::DSL::PeriodParser.new(path: path)
      end

      # Define a scheduled entry and evaluate its jobs block.
      #
      # @param periods [Array<String, Symbol, Wheneverd::Duration, Array<Symbol>>]
      # @param at [String, Array<String>, nil]
      # @return [Wheneverd::Entry]
      def every(*periods, at: nil, &block)
        raise InvalidPeriodError.new("every() requires a block", path: path) unless block

        raise InvalidPeriodError.new("every() requires a period", path: path) if periods.empty?

        period = periods.length == 1 ? periods.first : periods
        trigger = @period_parser.trigger_for(period, at: at)
        entry = Wheneverd::Entry.new(trigger: trigger)

        schedule.add_entry(entry)

        with_current_entry(entry) { instance_eval(&block) }

        entry
      end

      # Add a oneshot command job to the current `every` entry.
      #
      # @example String command
      #   command "echo hello"
      #
      # @example argv command
      #   command ["echo", "hello world"]
      #
      # @param command_value [String, Array<String>]
      # @return [void]
      def command(command_value)
        ensure_in_every_block!("command")

        @current_entry.add_job(Wheneverd::Job::Command.new(command: command_value))
      rescue Wheneverd::InvalidCommandError => e
        raise LoadError.new(e.message, path: path)
      end

      # Add a oneshot command job that runs via `/bin/bash -lc`.
      #
      # @example
      #   shell "echo hello | sed -e s/hello/hi/"
      #
      # @param script [String] non-empty script to pass as `bash -lc <script>`
      # @param shell [String] shell executable (default: "/bin/bash")
      # @return [void]
      def shell(script, shell: "/bin/bash")
        ensure_in_every_block!("shell")
        script_stripped = normalize_shell_script(script)
        shell_executable = normalize_shell_executable(shell)
        command([shell_executable, "-lc", script_stripped])
      end

      private

      def ensure_in_every_block!(name)
        return if @current_entry

        raise LoadError.new("#{name}() must be called inside every() block", path: path)
      end

      def normalize_shell_script(script)
        unless script.is_a?(String)
          raise LoadError.new("shell() script must be a String (got #{script.class})",
                              path: path)
        end

        stripped = script.strip
        raise LoadError.new("shell() script must not be empty", path: path) if stripped.empty?

        stripped
      end

      def normalize_shell_executable(shell)
        stripped = shell.to_s.strip
        raise LoadError.new("shell() shell must not be empty", path: path) if stripped.empty?

        stripped
      end

      def with_current_entry(entry)
        previous_entry = @current_entry
        @current_entry = entry
        yield
      ensure
        @current_entry = previous_entry
      end
    end
  end
end
