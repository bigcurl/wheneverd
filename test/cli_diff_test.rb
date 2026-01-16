# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLIDiffTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one_and_shows_added_diff_when_units_are_not_installed
    with_inited_unit_dir("missing_units") do |unit_dir|
      timer = first_timer
      status, out, err = run_diff(unit_dir)
      assert_diff_added(status, out, err, unit_dir, timer)
    end
  end

  def test_exits_zero_when_no_differences
    with_installed_units do |unit_dir|
      status, out, err = run_diff(unit_dir)
      assert_equal 0, status
      assert_equal "", err
      assert_equal "", out
    end
  end

  def test_exits_one_and_shows_removed_lines_when_installed_unit_was_modified
    with_installed_units do |unit_dir|
      timer = first_timer
      File.open(File.join(unit_dir, timer), "a") { |f| f.puts "# local edit" }
      status, out, err = run_diff(unit_dir)
      assert_diff_contains(status, out, err, timer, "-# local edit")
    end
  end

  def test_exits_one_and_shows_added_lines_when_installed_unit_is_missing_lines
    with_installed_units do |unit_dir|
      timer = first_timer
      remove_exact_line(File.join(unit_dir, timer), "Persistent=true\n")
      status, out, err = run_diff(unit_dir)
      assert_diff_contains(status, out, err, timer, "+Persistent=true")
    end
  end

  def test_exits_one_and_shows_diff_for_stale_units_on_disk
    with_installed_units do |unit_dir|
      stale_timer = "wheneverd-demo-000000000000.timer"
      stale_path = write_stale_timer(unit_dir, stale_timer)
      status, out, err = run_diff(unit_dir)
      assert_diff_removed(status, out, err, stale_timer, stale_path)
    end
  end

  def test_returns_two_on_error
    with_project_dir do
      status, out, err = run_cli(["diff", "--schedule", "missing.rb"])
      assert_equal 2, status
      assert_equal "", out
      assert_includes err, "Schedule file not found"
    end
  end

  private

  def with_inited_unit_dir(name)
    with_inited_project_dir do |project_dir|
      yield File.join(project_dir, name)
    end
  end

  def with_installed_units
    with_inited_unit_dir("tmp_units") do |unit_dir|
      assert_equal 0, run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir]).first
      yield unit_dir
    end
  end

  def run_diff(unit_dir)
    run_cli(["diff", "--identifier", "demo", "--unit-dir", unit_dir])
  end

  def first_timer
    expected_timer_basenames(identifier: "demo").fetch(0)
  end

  def remove_exact_line(path, line)
    File.write(path, File.read(path).lines.reject { |l| l == line }.join)
  end

  def write_stale_timer(unit_dir, basename)
    path = File.join(unit_dir, basename)
    File.write(path, "#{Wheneverd::Systemd::Renderer::MARKER_PREFIX} test\n# stale\n")
    path
  end

  def assert_diff_added(status, out, err, unit_dir, timer)
    assert_equal 1, status
    assert_equal "", err
    assert_includes out, "diff --wheneverd #{timer}"
    assert_includes out, "--- /dev/null"
    assert_includes out, "+++ #{File.join(File.expand_path(unit_dir), timer)}"
  end

  def assert_diff_contains(status, out, err, timer, expected_line)
    assert_equal 1, status
    assert_equal "", err
    assert_includes out, "diff --wheneverd #{timer}"
    assert_includes out, expected_line
  end

  def assert_diff_removed(status, out, err, timer, path)
    assert_equal 1, status
    assert_equal "", err
    assert_includes out, "diff --wheneverd #{timer}"
    assert_includes out, "--- #{path}"
    assert_includes out, "+++ /dev/null"
    assert_includes out, "-# stale"
  end
end
