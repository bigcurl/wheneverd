# frozen_string_literal: true

module Wheneverd
  module DSL
    # The evaluation context used for schedule files.
    #
    # The schedule file is evaluated via `instance_eval`, so methods defined here become available
    # as the schedule DSL (`every`, `command`).
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
      # @param roles [Object] stored but currently not used for filtering
      # @return [Wheneverd::Entry]
      def every(*periods, at: nil, roles: nil, &block)
        raise InvalidPeriodError.new("every() requires a block", path: path) unless block

        raise InvalidPeriodError.new("every() requires a period", path: path) if periods.empty?

        period = periods.length == 1 ? periods.first : periods
        trigger = @period_parser.trigger_for(period, at: at)
        entry = Wheneverd::Entry.new(trigger: trigger, roles: roles)

        schedule.add_entry(entry)

        with_current_entry(entry) { instance_eval(&block) }

        entry
      end

      # Add a oneshot command job to the current `every` entry.
      #
      # @param command_str [String]
      # @return [void]
      def command(command_str)
        unless @current_entry
          raise LoadError.new("command() must be called inside every() block",
                              path: path)
        end

        @current_entry.add_job(Wheneverd::Job::Command.new(command: command_str))
      rescue Wheneverd::InvalidCommandError => e
        raise LoadError.new(e.message, path: path)
      end

      private

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
