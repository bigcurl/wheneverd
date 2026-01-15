# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd help` and the default command.
  #
  # The `--version` flag is supported here to match the common "help-or-version" UX.
  class CLI::Help < CLI
    def execute
      if version?
        puts Wheneverd::VERSION
        return 0
      end

      warn Wheneverd::CLI.help(invocation_path.split.first)
      1
    end
  end
end
