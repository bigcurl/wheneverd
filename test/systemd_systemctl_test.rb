# frozen_string_literal: true

require_relative "test_helper"

class SystemdSystemctlTest < Minitest::Test
  def with_capture3_stub(exitstatus:, stdout: "", stderr: "")
    calls = []
    Thread.current[:open3_capture3_stub] = {
      calls: calls,
      stdout: stdout,
      stderr: stderr,
      exitstatus: exitstatus
    }
    yield calls
  ensure
    Thread.current[:open3_capture3_stub] = nil
  end

  def test_run_builds_user_systemctl_command_and_returns_output
    with_capture3_stub(exitstatus: 0, stdout: "ok\n", stderr: "") do |calls|
      out, err = Wheneverd::Systemd::Systemctl.run("daemon-reload")
      assert_equal "ok\n", out
      assert_equal "", err
      assert_equal [["systemctl", "--user", "--no-pager", "daemon-reload"], {}], calls.fetch(0)
    end
  end

  def test_run_omits_user_flag_when_user_false
    with_capture3_stub(exitstatus: 0) do |calls|
      Wheneverd::Systemd::Systemctl.run("daemon-reload", user: false)
      refute_includes calls.fetch(0).fetch(0), "--user"
    end
  end

  def test_run_raises_systemctl_error_on_failure_with_details
    with_capture3_stub(exitstatus: 1, stdout: "oops\n", stderr: "nope\n") do
      error = assert_raises(Wheneverd::Systemd::SystemctlError) do
        Wheneverd::Systemd::Systemctl.run("daemon-reload")
      end

      assert_includes error.message, "status: 1"
      assert_includes error.message, "stdout: oops"
      assert_includes error.message, "stderr: nope"
    end
  end
end
