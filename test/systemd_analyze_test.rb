# frozen_string_literal: true

require_relative "test_helper"

class SystemdAnalyzeTest < Minitest::Test
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

  def test_calendar_builds_command_and_returns_output
    with_capture3_stub(exitstatus: 0, stdout: "ok\n", stderr: "") do |calls|
      out, err = Wheneverd::Systemd::Analyze.calendar("hourly")
      assert_equal "ok\n", out
      assert_equal "", err
      assert_equal [%w[systemd-analyze calendar hourly], {}], calls.fetch(0)
    end
  end

  def test_verify_builds_user_verify_command
    with_capture3_stub(exitstatus: 0) do |calls|
      Wheneverd::Systemd::Analyze.verify(["/tmp/a.timer", "/tmp/a.service"], user: true)
      assert_equal(
        [["systemd-analyze", "--user", "verify", "/tmp/a.timer", "/tmp/a.service"], {}],
        calls.fetch(0)
      )
    end
  end

  def test_calendar_raises_systemd_analyze_error_on_failure_with_details
    with_capture3_stub(exitstatus: 1, stdout: "oops\n", stderr: "nope\n") do
      error = assert_raises(Wheneverd::Systemd::SystemdAnalyzeError) do
        Wheneverd::Systemd::Analyze.calendar("hourly")
      end
      assert_includes error.message, "status: 1"
      assert_includes error.message, "stdout: oops"
      assert_includes error.message, "stderr: nope"
    end
  end

  def test_calendar_raises_systemd_analyze_error_when_missing
    error = assert_raises(Wheneverd::Systemd::SystemdAnalyzeError) do
      Wheneverd::Systemd::Analyze.calendar("hourly", systemd_analyze: "/no/such/systemd-analyze")
    end
    assert_includes error.message, "systemd-analyze not found"
  end
end
