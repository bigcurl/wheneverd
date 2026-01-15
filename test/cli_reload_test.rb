# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLIReloadSuccessTest < Minitest::Test
  include CLITestHelpers

  def test_exits_zero
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      status, _out, err, _calls = run_reload_with_capture3_stub(unit_dir: unit_dir)
      assert_cli_success(status, err)
    end
  end

  def test_writes_unit_files
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      status, _out, err, _calls = run_reload_with_capture3_stub(unit_dir: unit_dir)
      assert_cli_success(status, err)
      assert File.exist?(File.join(unit_dir, "wheneverd-demo-e0-j0.timer"))
    end
  end

  def test_runs_daemon_reload
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      status, _out, err, calls = run_reload_with_capture3_stub(unit_dir: unit_dir)
      assert_cli_success(status, err)
      assert_systemctl_call(calls, 0, SYSTEMCTL_USER_PREFIX + ["daemon-reload"])
    end
  end

  def test_runs_restart
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      status, _out, err, calls = run_reload_with_capture3_stub(unit_dir: unit_dir)
      assert_cli_success(status, err)
      assert_systemctl_call_starts_with(calls, 1, SYSTEMCTL_USER_PREFIX + ["restart"],
                                        includes: "wheneverd-demo-e5-j0.timer")
    end
  end
end

class CLIReloadScheduleMissingTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      status, _out, _err = run_cli(["reload", "--unit-dir", unit_dir])
      assert_equal 1, status
    end
  end

  def test_prints_error_message
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      _status, out, err = run_cli(["reload", "--unit-dir", unit_dir])
      assert_equal "", out
      assert_includes err, "Schedule file not found"
    end
  end
end

class CLIReloadEmptyScheduleTest < Minitest::Test
  include CLITestHelpers

  def test_makes_no_systemctl_calls
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      write_empty_schedule
      status, _out, err, calls = run_reload_with_capture3_stub(unit_dir: unit_dir)
      assert_cli_success(status, err)
      assert_equal [], calls
    end
  end

  def test_prints_nothing
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      write_empty_schedule
      status, out, err, _calls = run_reload_with_capture3_stub(unit_dir: unit_dir)
      assert_cli_success(status, err)
      assert_equal "", out
    end
  end
end

class CLIReloadSystemctlFailureTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      status, _out, _err, _calls = run_reload_with_capture3_stub(unit_dir: unit_dir,
                                                                 exitstatus: 1,
                                                                 stderr: "no bus\n")
      assert_equal 1, status
    end
  end

  def test_prints_systemctl_failed
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      _status, _out, err, _calls = run_reload_with_capture3_stub(unit_dir: unit_dir,
                                                                 exitstatus: 1,
                                                                 stderr: "no bus\n")
      assert_includes err, "systemctl failed"
    end
  end

  def test_only_calls_daemon_reload
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      _status, _out, _err, calls = run_reload_with_capture3_stub(unit_dir: unit_dir,
                                                                 exitstatus: 1,
                                                                 stderr: "no bus\n")
      assert_equal 1, calls.length
      assert_systemctl_call(calls, 0, SYSTEMCTL_USER_PREFIX + ["daemon-reload"])
    end
  end

  def test_writes_units_before_systemctl_failure
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      run_reload_with_capture3_stub(unit_dir: unit_dir, exitstatus: 1, stderr: "no bus\n")
      assert File.exist?(File.join(unit_dir, "wheneverd-demo-e0-j0.timer"))
    end
  end
end
