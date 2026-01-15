# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_subprocess_test_helpers"

class CLISystemdAnalyzeTest < Minitest::Test
  include CLISubprocessTestHelpers

  def test_rendered_on_calendar_values_parse_with_systemd_analyze_calendar
    analyze = require_executable!("systemd-analyze")
    true_bin = absolute_true_path || "true"

    with_temp_project_dir { |project_dir| assert_calendars_ok(analyze, project_dir, true_bin) }
  end

  private

  def assert_calendars_ok(analyze, project_dir, true_bin)
    write_schedule(project_dir, schedule_contents(true_bin))
    status, out, err = run_exe(["show", "--identifier", "demo"], chdir: project_dir)
    assert_equal 0, status
    assert_equal "", err

    values = on_calendar_values(out)
    refute_empty values
    values.each { |value| assert_systemd_analyze_calendar_ok(analyze, value) }
  end

  def require_executable!(name)
    path = find_executable(name)
    skip "#{name} not available" unless path
    path
  end

  def schedule_contents(true_bin)
    <<~RUBY
      # frozen_string_literal: true

      every :hour do
        command "#{true_bin}"
      end

      every 1.day, at: "4:30 am" do
        command "#{true_bin}"
      end
    RUBY
  end

  def absolute_true_path
    %w[/usr/bin/true /bin/true].find { |p| File.file?(p) && File.executable?(p) }
  end

  def on_calendar_values(output)
    output.lines
          .grep(/\AOnCalendar=/)
          .map { |line| line.delete_prefix("OnCalendar=").strip }
          .uniq
  end

  def assert_systemd_analyze_calendar_ok(analyze, value)
    _stdout, stderr, status = Open3.capture3(analyze, "calendar", value)
    assert_equal 0, status.exitstatus, stderr
  end
end
