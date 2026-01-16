# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLIStatusTest < Minitest::Test
  include CLITestHelpers

  def test_runs_list_timers_and_status_for_each_installed_timer
    with_installed_units do |unit_dir|
      status, _out, err, calls = run_status(unit_dir)
      assert_cli_success(status, err)
      assert_status_calls(calls, expected_timer_units)
    end
  end

  def test_returns_nonzero_when_systemctl_fails
    with_installed_units do |unit_dir|
      status, _out, err, calls = run_status(unit_dir, exitstatus: 1, stderr: "boom\n")
      assert_equal 1, status
      assert_includes err, "systemctl failed"
      assert_includes err, "boom"
      assert_includes calls.fetch(0).fetch(0), "list-timers"
    end
  end

  def test_exits_zero_and_does_not_call_systemctl_when_no_timers_installed
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "empty_units")
      FileUtils.mkdir_p(unit_dir)
      status, out, err, calls = run_status(unit_dir)
      assert_cli_success(status, err)
      assert_equal "", out
      assert_equal [], calls
    end
  end

  private

  def with_installed_units
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir]).first
      yield unit_dir
    end
  end

  def run_status(unit_dir, **kwargs)
    run_cli_with_capture3_stub(["status", "--identifier", "demo", "--unit-dir", unit_dir], **kwargs)
  end

  def expected_timer_units
    expected_timer_basenames(identifier: "demo").sort
  end

  def assert_status_calls(calls, expected_timers)
    assert_list_timers_call(calls, expected_timers)
    assert_status_unit_calls(calls, expected_timers)
  end

  def assert_list_timers_call(calls, expected_timers)
    assert_systemctl_call_starts_with(
      calls,
      0,
      SYSTEMCTL_USER_PREFIX + ["list-timers", "--all"],
      includes: expected_timers
    )
  end

  def assert_status_unit_calls(calls, expected_timers)
    status_calls = calls.drop(1).map(&:first)
    assert_equal expected_timers.length, status_calls.length
    assert_equal expected_timers, status_calls.map(&:last).sort
    status_calls.each { |args| assert_equal SYSTEMCTL_USER_PREFIX + ["status", args.last], args }
  end
end
