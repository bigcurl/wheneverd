# frozen_string_literal: true

require "fileutils"

module Wheneverd
  class CLI::Init < CLI
    option "--force", :flag, "Overwrite existing file"

    TEMPLATE = <<~RUBY
      # frozen_string_literal: true

      # This file is evaluated as Ruby.
      #
      # Supported `every` period forms:
      # - interval strings: "5m", "1h", "2d"
      # - duration objects: 1.day, 2.hours
      # - symbol shortcuts: :hour, :day, :month, :year, :reboot
      # - day selectors: :sunday, :weekday, :weekend (use `at:` for specific times)
      # - cron strings (5 fields): "0 0 27-31 * *" (limited subset)

      every "5m" do
        command "echo hello"
      end

      every 1.day, at: "4:30 am" do
        command "echo four_thirty"
      end

      every 1.day, at: ["4:30 am", "6:00 pm"] do
        command "echo twice_daily"
      end

      every :hour do
        command "echo hourly"
      end

      every :sunday, at: "12pm" do
        command "echo weekly"
      end

      every "0 0 27-31 * *" do
        command "echo raw_cron"
      end
    RUBY

    def execute
      path = File.expand_path(schedule)
      if File.exist?(path) && !force?
        warn "#{path}: already exists (use --force to overwrite)"
        return 1
      end

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, TEMPLATE)
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end
