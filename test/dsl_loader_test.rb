# frozen_string_literal: true

require_relative "test_helper"
require "fileutils"
require "tmpdir"

module DSLLoaderTestHelpers
  def setup
    super
    @tmpdir = Dir.mktmpdir("wheneverd-")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir
    super
  end

  private

  def load_schedule(source)
    path = write_schedule(source)
    Wheneverd::DSL::Loader.load_file(path)
  end

  def write_schedule(source)
    path = File.join(@tmpdir, "schedule.rb")
    File.write(path, source)
    path
  end
end

class DSLLoaderIntervalAndDurationTest < Minitest::Test
  include DSLLoaderTestHelpers

  def test_loads_interval_string_every_block
    schedule = load_schedule(<<~RUBY)
      every "5m" do
        command "echo hello"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Interval, entry.trigger
    assert_equal 300, entry.trigger.seconds
    assert_equal ["echo hello"], entry.jobs.map(&:command)
  end

  def test_loads_argv_command
    schedule = load_schedule(<<~RUBY)
      every "5m" do
        command ["echo", "hello world"]
      end
    RUBY

    job = schedule.entries.fetch(0).jobs.fetch(0)
    assert_equal ["echo", "hello world"], job.argv
    assert_equal "echo \"hello world\"", job.command
  end

  def test_loads_shell_helper
    schedule = load_schedule(<<~RUBY)
      every "5m" do
        shell "echo hello | sed -e s/hello/hi/"
      end
    RUBY

    job = schedule.entries.fetch(0).jobs.fetch(0)
    assert_equal ["/bin/bash", "-lc", "echo hello | sed -e s/hello/hi/"], job.argv
  end

  def test_loads_duration_with_at_as_calendar
    schedule = load_schedule(<<~RUBY)
      every 1.day, at: "4:30 am" do
        command "echo four_thirty"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Calendar, entry.trigger
    assert_equal ["day@4:30 am"], entry.trigger.on_calendar
    assert_equal ["echo four_thirty"], entry.jobs.map(&:command)
  end

  def test_loads_duration_without_at_as_interval
    schedule = load_schedule(<<~RUBY)
      every 1.day do
        command "echo daily"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Interval, entry.trigger
    assert_equal 86_400, entry.trigger.seconds
  end

  def test_loads_duration_with_at_array_as_calendar
    schedule = load_schedule(<<~RUBY)
      every 1.day, at: ["4:30 am", "6:00 pm"] do
        command "echo twice_daily"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Calendar, entry.trigger
    assert_equal ["day@4:30 am", "day@6:00 pm"], entry.trigger.on_calendar
  end

  def test_loads_cron_string_as_calendar_trigger
    schedule = load_schedule(<<~RUBY)
      every "0 0 27-31 * *" do
        command "echo raw_cron"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Calendar, entry.trigger
    assert_equal ["cron:0 0 27-31 * *"], entry.trigger.on_calendar
  end
end

class DSLLoaderSymbolPeriodsTest < Minitest::Test
  include DSLLoaderTestHelpers

  def test_loads_symbol_shortcut_hour
    schedule = load_schedule(<<~RUBY)
      every :hour do
        command "echo hourly"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Calendar, entry.trigger
    assert_equal ["hour"], entry.trigger.on_calendar
  end

  def test_reboot_symbol_is_rejected
    schedule_path = write_schedule(<<~RUBY)
      every :reboot do
        command "echo reboot"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, ":reboot"
    assert_includes error.message, "not supported"
  end

  def test_loads_day_selector_symbol_with_at
    schedule = load_schedule(<<~RUBY)
      every :sunday, at: "12pm" do
        command "echo weekly"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Calendar, entry.trigger
    assert_equal ["sunday@12pm"], entry.trigger.on_calendar
  end

  def test_loads_weekday_symbol
    schedule = load_schedule(<<~RUBY)
      every :weekday do
        command "echo weekday"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_equal ["weekday"], entry.trigger.on_calendar
  end

  def test_loads_weekend_symbol
    schedule = load_schedule(<<~RUBY)
      every :weekend do
        command "echo weekend"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_equal ["weekend"], entry.trigger.on_calendar
  end

  def test_loads_multiple_day_symbols_as_calendar_trigger
    schedule = load_schedule(<<~RUBY)
      every :tuesday, :wednesday, at: "12pm" do
        command "echo midweek"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Calendar, entry.trigger
    assert_equal ["tuesday@12pm", "wednesday@12pm"], entry.trigger.on_calendar
  end

  def test_loads_period_symbol_array_as_calendar_trigger
    schedule = load_schedule(<<~RUBY)
      every %i[tuesday wednesday], at: "12pm" do
        command "echo midweek"
      end
    RUBY

    entry = schedule.entries.fetch(0)
    assert_instance_of Wheneverd::Trigger::Calendar, entry.trigger
    assert_equal ["tuesday@12pm", "wednesday@12pm"], entry.trigger.on_calendar
  end

  def test_loads_multiple_day_symbols_with_at_array_as_calendar_trigger
    entry = load_schedule(<<~RUBY).entries.fetch(0)
      every :tuesday, :wednesday, at: ["4:30 am", "6:00 pm"] do
        command "echo twice_midweek"
      end
    RUBY

    assert_instance_of Wheneverd::Trigger::Calendar, entry.trigger
    assert_equal(
      ["tuesday@4:30 am", "tuesday@6:00 pm", "wednesday@4:30 am", "wednesday@6:00 pm"],
      entry.trigger.on_calendar
    )
  end
end

class DSLLoaderPeriodErrorsTest < Minitest::Test
  include DSLLoaderTestHelpers

  def test_invalid_interval_raises_error_with_path
    schedule_path = write_schedule(<<~RUBY)
      every "0m" do
        command "echo no"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "Interval must be positive"
  end

  def test_interval_string_does_not_accept_at
    schedule_path = write_schedule(<<~RUBY)
      every "5m", at: "12pm" do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "interval periods"
  end

  def test_cron_string_does_not_accept_at
    schedule_path = write_schedule(<<~RUBY)
      every "0 0 27-31 * *", at: "12pm" do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "cron periods"
  end

  def test_duration_at_is_rejected_for_non_daily_durations
    schedule_path = write_schedule(<<~RUBY)
      every 2.days, at: "4:30 am" do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "at: is only supported"
  end

  def test_every_requires_a_block
    schedule_path = write_schedule(<<~RUBY)
      every "5m"
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "requires a block"
  end

  def test_every_rejects_unknown_period_type
    schedule_path = write_schedule(<<~RUBY)
      every Object.new do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "Unsupported period type"
  end

  def test_every_rejects_unrecognized_string_period
    schedule_path = write_schedule(<<~RUBY)
      every "not a schedule" do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "Unrecognized period"
  end

  def test_unknown_symbol_period_raises_error
    schedule_path = write_schedule(<<~RUBY)
      every :fortnight do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "Unknown period symbol"
  end

  def test_reboot_does_not_accept_at
    schedule_path = write_schedule(<<~RUBY)
      every :reboot, at: "12pm" do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, ":reboot"
    assert_includes error.message, "not supported"
  end
end

class DSLLoaderAtValidationErrorsTest < Minitest::Test
  include DSLLoaderTestHelpers

  def test_invalid_at_type_raises_error_with_path
    schedule_path = write_schedule(<<~RUBY)
      every 1.day, at: 123 do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidAtError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "at:"
  end

  def test_invalid_at_array_rejects_non_string
    schedule_path = write_schedule(<<~RUBY)
      every 1.day, at: ["4:30 am", 123] do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidAtError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "Array of Strings"
  end

  def test_invalid_at_array_rejects_empty
    schedule_path = write_schedule(<<~RUBY)
      every 1.day, at: [] do
        command "echo nope"
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::InvalidAtError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "must not be empty"
  end
end

class DSLLoaderCommandAndEvalErrorsTest < Minitest::Test
  include DSLLoaderTestHelpers

  def test_invalid_command_raises_error_with_path
    schedule_path = write_schedule(<<~RUBY)
      every "5m" do
        command ""
      end
    RUBY

    error = assert_raises(Wheneverd::DSL::LoadError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "Command must not be empty"
  end

  def test_command_outside_every_is_rejected
    schedule_path = write_schedule(<<~RUBY)
      command "echo nope"
    RUBY

    error = assert_raises(Wheneverd::DSL::LoadError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "inside every()"
  end

  def test_unknown_method_in_schedule_is_wrapped_as_load_error
    schedule_path = write_schedule(<<~RUBY)
      totally_unknown_dsl_method "nope"
    RUBY

    error = assert_raises(Wheneverd::DSL::LoadError) { Wheneverd::DSL::Loader.load_file(schedule_path) }
    assert_includes error.message, schedule_path
    assert_includes error.message, "totally_unknown_dsl_method"
  end
end
