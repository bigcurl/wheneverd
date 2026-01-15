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
      # - symbol shortcuts: :hour, :day, :month, :year
      # - day selectors: :monday..:sunday, :weekday, :weekend (multiple day symbols supported)
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

      every :tuesday, :wednesday, at: "12pm" do
        command "echo midweek"
      end

      every "0 0 27-31 * *" do
        command "echo raw_cron"
      end
    RUBY

    def execute
      path = File.expand_path(schedule)
      return 1 if refuse_overwrite_without_force?(path)

      existed = write_template(path)
      puts "#{existed ? 'Overwrote' : 'Wrote'} schedule template to #{path}"
      0
    rescue StandardError => e
      handle_error(e)
    end

    private

    def refuse_overwrite_without_force?(path)
      return false unless File.exist?(path) && !force?

      warn "#{path}: already exists (use --force to overwrite)"
      true
    end

    def write_template(path)
      existed = File.exist?(path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, TEMPLATE)
      existed
    end
  end
end
