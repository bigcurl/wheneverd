# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLIDeactivateSuccessTest < Minitest::Test
  include CLITestHelpers

  def test_exits_zero
    with_inited_project_dir do
      status, _out, _err, _calls = run_deactivate_with_capture3_stub
      assert_equal 0, status
    end
  end

  def test_prints_timer_units
    with_inited_project_dir do
      status, out, err, _calls = run_deactivate_with_capture3_stub
      assert_cli_success(status, err)
      assert_includes out, expected_timer_basenames.fetch(0)
    end
  end

  def test_runs_stop
    with_inited_project_dir do
      status, _out, err, calls = run_deactivate_with_capture3_stub
      assert_cli_success(status, err)
      assert_systemctl_call_starts_with(calls, 0, SYSTEMCTL_USER_PREFIX + ["stop"],
                                        includes: expected_timer_basenames)
    end
  end

  def test_runs_disable
    with_inited_project_dir do
      status, _out, err, calls = run_deactivate_with_capture3_stub
      assert_cli_success(status, err)
      assert_systemctl_call_starts_with(calls, 1, SYSTEMCTL_USER_PREFIX + ["disable"],
                                        includes: expected_timer_basenames)
    end
  end
end

class CLIDeactivateScheduleMissingTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one
    with_project_dir do
      status, _out, _err = run_cli(["deactivate"])
      assert_equal 1, status
    end
  end

  def test_prints_error_message
    with_project_dir do
      _status, out, err = run_cli(["deactivate"])
      assert_equal "", out
      assert_includes err, "Schedule file not found"
    end
  end
end

class CLIDeactivateEmptyScheduleTest < Minitest::Test
  include CLITestHelpers

  def test_makes_no_systemctl_calls
    with_project_dir do
      write_empty_schedule
      status, _out, err, calls = run_deactivate_with_capture3_stub
      assert_cli_success(status, err)
      assert_equal [], calls
    end
  end

  def test_prints_nothing
    with_project_dir do
      write_empty_schedule
      status, out, err, _calls = run_deactivate_with_capture3_stub
      assert_cli_success(status, err)
      assert_equal "", out
    end
  end
end

class CLIDeactivateSystemctlFailureTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one
    with_inited_project_dir do
      status, _out, _err, _calls = run_deactivate_with_capture3_stub(exitstatus: 1,
                                                                     stderr: "no bus\n")
      assert_equal 1, status
    end
  end

  def test_prints_systemctl_failed
    with_inited_project_dir do
      _status, _out, err, _calls = run_deactivate_with_capture3_stub(exitstatus: 1,
                                                                     stderr: "no bus\n")
      assert_includes err, "systemctl failed"
    end
  end

  def test_only_calls_stop
    with_inited_project_dir do
      _status, _out, _err, calls = run_deactivate_with_capture3_stub(exitstatus: 1,
                                                                     stderr: "no bus\n")
      assert_equal 1, calls.length
      assert_systemctl_call_starts_with(calls, 0, SYSTEMCTL_USER_PREFIX + ["stop"])
    end
  end
end
