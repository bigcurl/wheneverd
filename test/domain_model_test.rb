# frozen_string_literal: true

require_relative "test_helper"

class DomainModelTest < Minitest::Test
  def test_interval_parses_supported_units
    assert_equal 30, Wheneverd::Interval.parse("30s")
    assert_equal 300, Wheneverd::Interval.parse("5m")
    assert_equal 3600, Wheneverd::Interval.parse("1h")
    assert_equal 86_400, Wheneverd::Interval.parse("1d")
    assert_equal 604_800, Wheneverd::Interval.parse("1w")
  end

  def test_interval_rejects_invalid_inputs
    error = assert_raises(Wheneverd::InvalidIntervalError) { Wheneverd::Interval.parse("abc") }
    assert_includes error.message, "Invalid interval"

    assert_raises(Wheneverd::InvalidIntervalError) { Wheneverd::Interval.parse("0m") }
    assert_raises(Wheneverd::InvalidIntervalError) { Wheneverd::Interval.parse("-5m") }
    assert_raises(Wheneverd::InvalidIntervalError) { Wheneverd::Interval.parse("5") }
    assert_raises(Wheneverd::InvalidIntervalError) { Wheneverd::Interval.parse("5mm") }
    assert_raises(Wheneverd::InvalidIntervalError) { Wheneverd::Interval.parse(nil) }
  end

  def test_duration_wraps_seconds
    duration = Wheneverd::Duration.new(42)
    assert_equal 42, duration.seconds
    assert_equal 42, duration.to_i

    assert_raises(ArgumentError) { Wheneverd::Duration.new(1.0) }
    assert_raises(ArgumentError) { Wheneverd::Duration.new(0) }
  end

  def test_numeric_duration_helpers_singular
    assert_equal 1, 1.second.to_i
    assert_equal 60, 1.minute.to_i
    assert_equal 3600, 1.hour.to_i
    assert_equal 86_400, 1.day.to_i
    assert_equal 604_800, 1.week.to_i
  end

  def test_numeric_duration_helpers_plural_seconds_and_minutes
    assert_equal 2, 2.seconds.to_i
    assert_equal 120, 2.minutes.to_i
  end

  def test_numeric_duration_helpers_plural_hours_days_weeks
    assert_equal 7200, 2.hours.to_i
    assert_equal 172_800, 2.days.to_i
    assert_equal 1_209_600, 2.weeks.to_i

    error = assert_raises(ArgumentError) { 1.5.hours }
    assert_includes error.message, "Integer receiver"
  end

  def test_job_command_validates_command
    command = Wheneverd::Job::Command.new(command: " echo hello ")
    assert_equal "echo hello", command.command

    assert_raises(Wheneverd::InvalidCommandError) { Wheneverd::Job::Command.new(command: "") }
    assert_raises(Wheneverd::InvalidCommandError) { Wheneverd::Job::Command.new(command: "   ") }

    error = assert_raises(Wheneverd::InvalidCommandError) { Wheneverd::Job::Command.new(command: 123) }
    assert_includes error.message, "String"
  end

  def test_triggers_render_timer_lines
    interval = Wheneverd::Trigger::Interval.new(seconds: 60)
    assert_equal ["OnUnitActiveSec=60"], interval.systemd_timer_lines

    boot = Wheneverd::Trigger::Boot.new(seconds: 5)
    assert_equal ["OnBootSec=5"], boot.systemd_timer_lines

    calendar = Wheneverd::Trigger::Calendar.new(on_calendar: %w[hourly daily])
    assert_equal ["OnCalendar=hourly", "OnCalendar=daily"], calendar.systemd_timer_lines
  end

  def test_trigger_validations
    assert_raises(ArgumentError) { Wheneverd::Trigger::Interval.new(seconds: "60") }
    assert_raises(ArgumentError) { Wheneverd::Trigger::Interval.new(seconds: 0) }

    assert_raises(ArgumentError) { Wheneverd::Trigger::Boot.new(seconds: "1") }
    assert_raises(ArgumentError) { Wheneverd::Trigger::Boot.new(seconds: 0) }

    assert_raises(ArgumentError) { Wheneverd::Trigger::Calendar.new(on_calendar: []) }
    assert_raises(ArgumentError) { Wheneverd::Trigger::Calendar.new(on_calendar: [" "]) }
    assert_raises(ArgumentError) { Wheneverd::Trigger::Calendar.new(on_calendar: "hourly") }
  end

  def test_entry_is_an_ordered_container
    entry = Wheneverd::Entry.new(trigger: Wheneverd::Trigger::Interval.new(seconds: 60))
    assert_equal [], entry.jobs
    entry.add_job(Wheneverd::Job::Command.new(command: "echo hi"))
    assert_equal 1, entry.jobs.length
  end

  def test_schedule_is_an_ordered_container
    schedule = Wheneverd::Schedule.new
    assert_equal [], schedule.entries
    entry = Wheneverd::Entry.new(trigger: Wheneverd::Trigger::Interval.new(seconds: 60))
    schedule.add_entry(entry)
    assert_equal [entry], schedule.entries
  end

  def test_entry_requires_a_trigger
    assert_raises(ArgumentError) { Wheneverd::Entry.new(trigger: nil) }
  end
end
