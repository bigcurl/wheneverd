# frozen_string_literal: true

module Wheneverd
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
