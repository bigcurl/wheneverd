# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLIActivateSuccessTest < Minitest::Test
  include CLITestHelpers

  def test_exits_zero
    with_inited_project_dir do
      status, _out, _err, _calls = run_activate_with_capture3_stub
      assert_equal 0, status
    end
  end

  def test_prints_timer_units
    with_inited_project_dir do
      status, out, err, _calls = run_activate_with_capture3_stub
      assert_cli_success(status, err)
      assert_includes out, expected_timer_basenames.fetch(0)
    end
  end

  def test_runs_daemon_reload
    with_inited_project_dir do
      status, _out, err, calls = run_activate_with_capture3_stub
      assert_cli_success(status, err)
      assert_systemctl_call(calls, 0, SYSTEMCTL_USER_PREFIX + ["daemon-reload"])
    end
  end

  def test_runs_enable_now
    with_inited_project_dir do
      status, _out, err, calls = run_activate_with_capture3_stub
      assert_cli_success(status, err)
      assert_systemctl_call_starts_with(calls, 1, SYSTEMCTL_USER_PREFIX + ["enable", "--now"],
                                        includes: expected_timer_basenames)
    end
  end
end

class CLIActivateScheduleMissingTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one
    with_project_dir do
      status, _out, _err = run_cli(["activate"])
      assert_equal 1, status
    end
  end

  def test_prints_error_message
    with_project_dir do
      _status, out, err = run_cli(["activate"])
      assert_equal "", out
      assert_includes err, "Schedule file not found"
    end
  end
end

class CLIActivateEmptyScheduleTest < Minitest::Test
  include CLITestHelpers

  def test_makes_no_systemctl_calls
    with_project_dir do
      write_empty_schedule
      status, _out, err, calls = run_activate_with_capture3_stub
      assert_cli_success(status, err)
      assert_equal [], calls
    end
  end

  def test_prints_nothing
    with_project_dir do
      write_empty_schedule
      status, out, err, _calls = run_activate_with_capture3_stub
      assert_cli_success(status, err)
      assert_equal "", out
    end
  end
end

class CLIActivateSystemctlFailureTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one
    with_inited_project_dir do
      status, _out, _err, _calls = run_activate_with_capture3_stub(exitstatus: 1,
                                                                   stderr: "no bus\n")
      assert_equal 1, status
    end
  end

  def test_prints_systemctl_failed
    with_inited_project_dir do
      _status, _out, err, _calls = run_activate_with_capture3_stub(exitstatus: 1,
                                                                   stderr: "no bus\n")
      assert_includes err, "systemctl failed"
    end
  end

  def test_only_calls_daemon_reload
    with_inited_project_dir do
      _status, _out, _err, calls = run_activate_with_capture3_stub(exitstatus: 1,
                                                                   stderr: "no bus\n")
      assert_equal 1, calls.length
      assert_systemctl_call(calls, 0, SYSTEMCTL_USER_PREFIX + ["daemon-reload"])
    end
  end
end
