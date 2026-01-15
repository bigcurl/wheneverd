# frozen_string_literal: true

module Wheneverd
  class CLI::Current < CLI
    def execute
      paths = Wheneverd::Systemd::UnitLister.list(identifier: identifier_value, unit_dir: unit_dir)
      print_unit_files(paths)
      0
    rescue StandardError => e
      handle_error(e)
    end

    def print_unit_files(paths)
      paths.each_with_index do |path, idx|
        puts "# #{path}"
        puts File.read(path)
        puts "" if idx < paths.length - 1
      end
    end
  end
end
