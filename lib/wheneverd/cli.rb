# frozen_string_literal: true

require "optparse"
require_relative "../wheneverd"

module Wheneverd
  module CLI
    module_function

    def run(argv)
      options = { verbose: false, print_version: false, print_help: false }
      parser = build_parser(options)

      parser.parse!(argv)
      if requested_output?(options)
        print_requested_output(parser, options)
        return 0
      end

      run_scaffold(parser, options)
    rescue OptionParser::ParseError => e
      handle_parse_error(e, parser)
    end

    def build_parser(options)
      OptionParser.new do |opts|
        opts.banner = "Usage: wheneverd [options]"

        opts.on("-v", "--version", "Print version") { options[:print_version] = true }
        opts.on("--verbose", "Verbose output") { options[:verbose] = true }
        opts.on("-h", "--help", "Print help") { options[:print_help] = true }
      end
    end

    def requested_output?(options)
      options[:print_version] || options[:print_help]
    end

    def print_requested_output(parser, options)
      puts Wheneverd::VERSION if options[:print_version]
      puts parser if options[:print_help]
    end

    def run_scaffold(parser, options)
      warn "wheneverd: not implemented yet (scaffold only)" if options[:verbose]
      warn parser
      1
    end

    def handle_parse_error(error, parser)
      warn error.message
      warn parser
      2
    end
  end
end
