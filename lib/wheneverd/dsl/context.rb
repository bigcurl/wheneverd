# frozen_string_literal: true

module Wheneverd
  module DSL
    class Context
      attr_reader :path, :schedule

      def initialize(path:)
        @path = path
        @schedule = Wheneverd::Schedule.new
        @current_entry = nil
        @period_parser = Wheneverd::DSL::PeriodParser.new(path: path)
      end

      def every(period, at: nil, roles: nil, &block)
        raise InvalidPeriodError.new("every() requires a block", path: path) unless block

        trigger = @period_parser.trigger_for(period, at: at)
        entry = Wheneverd::Entry.new(trigger: trigger, roles: roles)

        schedule.add_entry(entry)

        with_current_entry(entry) { instance_eval(&block) }

        entry
      end

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
