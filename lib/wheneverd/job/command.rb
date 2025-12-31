# frozen_string_literal: true

module Wheneverd
  module Job
    class Command
      attr_reader :command

      def initialize(command:)
        unless command.is_a?(String)
          raise InvalidCommandError, "Command must be a String (got #{command.class})"
        end

        command_stripped = command.strip
        raise InvalidCommandError, "Command must not be empty" if command_stripped.empty?

        @command = command_stripped
      end
    end
  end
end
