# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLIValidateTest < Minitest::Test
  include CLITestHelpers

  DUP_HOURLY_SCHEDULE = <<~RUBY
    # frozen_string_literal: true

    every :hour do
      command "echo a"
    end

    every :hour do
      command "echo b"
    end
  RUBY

  HOURLY_SCHEDULE = <<~RUBY
    # frozen_string_literal: true

    every :hour do
      command "echo a"
    end
  RUBY

  def test_validate_runs_systemd_analyze_calendar_for_each_unique_on_calendar
    with_project_dir do
      write_schedule(DUP_HOURLY_SCHEDULE)
      status, out, err, calls = run_validate("--verbose")
      assert_cli_success(status, err)
      assert_includes out, "OK OnCalendar=hourly"
      assert_equal 1, calls.length
      assert_equal %w[systemd-analyze calendar hourly], calls.fetch(0).fetch(0)
    end
  end

  def test_validate_prints_message_when_no_on_calendar_and_verbose
    with_project_dir do
      write_empty_schedule
      status, out, err, calls = run_validate("--verbose")
      assert_cli_success(status, err)
      assert_includes out, "No OnCalendar= values found"
      assert_equal [], calls
    end
  end

  def test_validate_verify_runs_systemd_analyze_verify
    with_project_dir do
      write_schedule(HOURLY_SCHEDULE)
      status, out, err, calls = run_validate("--verify", "--verbose")
      assert_cli_success(status, err)
      assert_includes out, "OK systemd-analyze --user verify"
      assert_equal %w[systemd-analyze --user verify], calls.fetch(1).fetch(0).take(3)
    end
  end

  def test_validate_returns_nonzero_when_systemd_analyze_calendar_fails
    with_project_dir do
      write_schedule(HOURLY_SCHEDULE)
      status, _out, err, calls = run_validate(exitstatus: 1, stderr: "boom\n")
      assert_equal 1, status
      assert_includes err, "systemd-analyze failed"
      assert_includes err, "boom"
      assert_equal %w[systemd-analyze calendar hourly], calls.fetch(0).fetch(0)
    end
  end

  private

  def run_validate(*args, **kwargs)
    run_cli_with_capture3_stub(["validate", *args], **kwargs)
  end

  def write_schedule(contents)
    FileUtils.mkdir_p("config")
    File.write(File.join("config", "schedule.rb"), contents)
  end
end
