# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLILingerEnableTest < Minitest::Test
  include CLITestHelpers

  def test_exits_zero
    with_project_dir do
      status, _out, err, _calls = run_cli_with_capture3_stub(["linger", "enable", "--user", "demo"])
      assert_cli_success(status, err)
    end
  end

  def test_calls_loginctl_enable_linger
    with_project_dir do
      status, _out, err, calls = run_cli_with_capture3_stub(["linger", "enable", "--user", "demo"])
      assert_cli_success(status, err)
      args, kwargs = calls.fetch(0)
      assert_equal ["loginctl", "--no-pager", "enable-linger", "demo"], args
      assert_equal({}, kwargs)
    end
  end

  def test_prints_confirmation
    with_project_dir do
      status, out, err, _calls = run_cli_with_capture3_stub(["linger", "enable", "--user", "demo"])
      assert_cli_success(status, err)
      assert_includes out, "Enabled lingering for demo"
    end
  end
end

class CLILingerDisableTest < Minitest::Test
  include CLITestHelpers

  def test_calls_loginctl_disable_linger
    with_project_dir do
      status, _out, err, calls = run_cli_with_capture3_stub(["linger", "disable", "--user", "demo"])
      assert_cli_success(status, err)
      args, _kwargs = calls.fetch(0)
      assert_equal ["loginctl", "--no-pager", "disable-linger", "demo"], args
    end
  end
end

class CLILingerStatusTest < Minitest::Test
  include CLITestHelpers

  def test_is_default_subcommand
    with_project_dir do
      status, _out, err, calls = run_cli_with_capture3_stub(["linger", "--user", "demo"],
                                                            stdout: "Linger=yes\n")
      assert_cli_success(status, err)
      args, _kwargs = calls.fetch(0)
      assert_equal ["loginctl", "--no-pager", "show-user", "demo", "-p", "Linger"], args
    end
  end

  def test_prints_linger_property_line
    with_project_dir do
      status, out, err, _calls = run_cli_with_capture3_stub(
        ["linger", "status", "--user", "demo"],
        stdout: "Linger=yes\n"
      )
      assert_cli_success(status, err)
      assert_equal "Linger=yes\n", out
    end
  end
end

class CLILingerFailureTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one_on_access_denied
    with_project_dir do
      status, _out, _err, _calls = run_cli_with_capture3_stub(
        ["linger", "enable", "--user", "demo"],
        exitstatus: 1,
        stderr: "Access denied\n"
      )
      assert_equal 1, status
    end
  end

  def test_prints_loginctl_failed_message
    with_project_dir do
      _status, out, err, _calls = run_cli_with_capture3_stub(
        ["linger", "enable", "--user", "demo"],
        exitstatus: 1,
        stderr: "Access denied\n"
      )
      assert_equal "", out
      assert_includes err, "loginctl failed"
      assert_includes err, "Access denied"
    end
  end

  def test_disable_failure_uses_handle_error
    with_project_dir do
      status, out, err, _calls = run_cli_with_capture3_stub(
        ["linger", "disable", "--user", "demo"],
        exitstatus: 1,
        stderr: "Access denied\n"
      )
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "loginctl failed"
    end
  end

  def test_status_failure_uses_handle_error
    with_project_dir do
      status, out, err, _calls = run_cli_with_capture3_stub(
        ["linger", "status", "--user", "demo"],
        exitstatus: 1,
        stderr: "Access denied\n"
      )
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "loginctl failed"
    end
  end
end
