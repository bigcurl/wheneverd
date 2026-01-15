# frozen_string_literal: true

module Wheneverd
  module Job
    # A oneshot command job rendered as `ExecStart=` in a `systemd` service unit.
    #
    # Note that the command is inserted into `ExecStart=` as-is. If you need shell features like
    # pipes, redirects, or environment variable expansion, wrap the command explicitly:
    #
    # @example
    #   command "/bin/bash -lc 'echo hello | sed -e s/hello/hi/'"
    class Command
      # @return [String]
      attr_reader :command

      # @param command [String] non-empty command to run
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
