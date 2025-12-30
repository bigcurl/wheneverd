# frozen_string_literal: true

require "optparse"
require_relative "../wheneverd"

module Wheneverd
  module CLI
    module_function

    def run(argv)
      options = { verbose: false }

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: wheneverd [options]"

        opts.on("-v", "--version", "Print version") do
          puts Wheneverd::VERSION
          return 0
        end

        opts.on("--verbose", "Verbose output") { options[:verbose] = true }
        opts.on("-h", "--help", "Print help") do
          puts opts
          return 0
        end
      end

      parser.parse!(argv)

      warn "wheneverd: not implemented yet (scaffold only)" if options[:verbose]
      warn parser.to_s
      1
    rescue OptionParser::ParseError => e
      warn e.message
      warn parser.to_s
      2
    end
  end
end

