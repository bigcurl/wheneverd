# frozen_string_literal: true

module Wheneverd
  module Job
    # A oneshot command job rendered as `ExecStart=` in a `systemd` service unit.
    #
    # This job accepts either:
    #
    # - A String (inserted into `ExecStart=` as-is, after stripping surrounding whitespace), or
    # - An argv Array (formatted/escaped into a systemd-compatible `ExecStart=` string).
    #
    # If you need shell features like pipes, redirects, or environment variable expansion, wrap
    # the command explicitly:
    #
    # @example
    #   command "/bin/bash -lc 'echo hello | sed -e s/hello/hi/'"
    #
    # @example argv form (safer argument handling)
    #   command ["/bin/bash", "-lc", "echo hello | sed -e s/hello/hi/"]
    class Command
      SAFE_UNQUOTED = %r{\A[A-Za-z0-9_@%+=:,./-]+\z}.freeze

      # Rendered `ExecStart=` value.
      #
      # @return [String]
      attr_reader :command

      # Original argv form (when constructed with an Array).
      #
      # @return [Array<String>, nil]
      attr_reader :argv

      # Stable signature used for unit naming.
      #
      # @return [String]
      attr_reader :signature

      # @param command [String, Array<String>] non-empty command to run
      def initialize(command:)
        @argv = nil
        @signature = nil
        @command = nil

        case command
        when String then init_string(command)
        when Array then init_argv(command)
        else
          raise InvalidCommandError,
                "Command must be a String or an Array (got #{command.class})"
        end
      end

      private

      def init_string(command)
        stripped = command.strip
        raise InvalidCommandError, "Command must not be empty" if stripped.empty?

        @command = stripped
        @signature = "command:#{@command}"
      end

      def init_argv(argv)
        normalized = normalize_argv(argv)
        @argv = normalized
        @command = format_execstart(normalized)
        @signature = ["command:argv", normalized.join("\n")].join("\n")
      end

      def normalize_argv(argv)
        raise InvalidCommandError, "Command argv must not be empty" if argv.empty?

        elements = argv.map { |arg| validate_argv_element(arg) }
        elements[0] = elements[0].strip
        raise InvalidCommandError, "Command argv executable must not be empty" if elements[0].empty?

        elements
      end

      def validate_argv_element(arg)
        unless arg.is_a?(String)
          raise InvalidCommandError, "Command argv elements must be Strings (got #{arg.class})"
        end

        if arg.match?(/[\0\r\n]/)
          raise InvalidCommandError,
                "Command argv elements must not include NUL or newlines"
        end

        arg
      end

      def format_execstart(argv)
        argv.map { |arg| format_exec_arg(arg) }.join(" ")
      end

      def format_exec_arg(arg)
        return "\"\"" if arg.empty?
        return arg if SAFE_UNQUOTED.match?(arg)

        "\"#{escape_exec_arg(arg)}\""
      end

      def escape_exec_arg(arg)
        arg.gsub(/[\\"]/) { |m| "\\#{m}" }
      end
    end
  end
end
