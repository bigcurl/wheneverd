# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLICurrentInstalledUnitsTest < Minitest::Test
  include CLITestHelpers

  def test_exits_zero
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir]).first
      status, _out, err = run_cli(["current", "--identifier", "demo", "--unit-dir", unit_dir])
      assert_cli_success(status, err)
    end
  end

  def test_includes_header_for_generated_units
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir]).first
      status, out, err = run_cli(["current", "--identifier", "demo", "--unit-dir", unit_dir])
      assert_cli_success(status, err)
      assert_includes out, "# #{File.join(unit_dir, 'wheneverd-demo-e0-j0.timer')}"
    end
  end

  def test_includes_generated_marker
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir]).first
      status, out, err = run_cli(["current", "--identifier", "demo", "--unit-dir", unit_dir])
      assert_cli_success(status, err)
      assert_includes out, Wheneverd::Systemd::Renderer::MARKER_PREFIX
    end
  end

  def test_excludes_units_without_generated_marker
    with_inited_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir]).first
      File.write(File.join(unit_dir, "wheneverd-demo-e99-j99.timer"), "# not generated\n")
      status, out, err = run_cli(["current", "--identifier", "demo", "--unit-dir", unit_dir])
      assert_cli_success(status, err)
      refute_includes out, "wheneverd-demo-e99-j99.timer"
    end
  end
end

class CLICurrentInvalidIdentifierTest < Minitest::Test
  include CLITestHelpers

  def test_exits_one
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      FileUtils.mkdir_p(unit_dir)
      status, _out, _err = run_cli(["current", "--identifier", "!!!", "--unit-dir", unit_dir])
      assert_equal 1, status
    end
  end

  def test_prints_error_message
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      FileUtils.mkdir_p(unit_dir)
      _status, out, err = run_cli(["current", "--identifier", "!!!", "--unit-dir", unit_dir])
      assert_equal "", out
      assert_includes err, "identifier must include at least one alphanumeric character"
    end
  end
end

class CLICurrentEmptyUnitDirTest < Minitest::Test
  include CLITestHelpers

  def test_prints_nothing_when_unit_dir_missing
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "missing_units")
      status, out, err = run_cli(["current", "--identifier", "demo", "--unit-dir", unit_dir])
      assert_cli_success(status, err)
      assert_equal "", out
    end
  end

  def test_prints_nothing_when_no_units_installed
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "empty_units")
      FileUtils.mkdir_p(unit_dir)
      status, out, err = run_cli(["current", "--identifier", "demo", "--unit-dir", unit_dir])
      assert_cli_success(status, err)
      assert_equal "", out
    end
  end
end
