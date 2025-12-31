# frozen_string_literal: true

require "clamp"
require_relative "../wheneverd"

module Wheneverd
  class CLI < Clamp::Command
    option ["-v", "--version"], :flag, "Print version"
    option "--verbose", :flag, "Verbose output"

    def execute
      if version?
        puts Wheneverd::VERSION
        return 0
      end

      warn "wheneverd: not implemented yet (scaffold only)" if verbose?
      warn help
      1
    end
  end
end
