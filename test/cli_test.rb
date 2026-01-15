# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLIHelpAndVersionTest < Minitest::Test
  include CLITestHelpers

  def test_help_prints_usage_and_exits_zero
    out, err = capture_io { Wheneverd::CLI.run("wheneverd", ["--help"]) }
    assert_includes out, "Usage:"
    assert_includes out, "wheneverd [OPTIONS]"
    assert_equal "", err
  end

  def test_version_prints_version_and_exits_zero
    status, out, err = run_cli(["--version"])
    assert_equal 0, status
    assert_includes out, Wheneverd::VERSION
    assert_equal "", err
  end

  def test_no_args_exits_one_and_prints_help_to_stderr
    status, out, err = run_cli([])
    assert_equal 1, status
    assert_equal "", out
    assert_includes err, "Usage:"
    assert_includes err, "wheneverd [OPTIONS]"
  end

  def test_invalid_option_exits_one_and_prints_error
    out, err = capture_io do
      exit_error = assert_raises(SystemExit) do
        Wheneverd::CLI.run("wheneverd", ["--definitely-not-a-real-flag"])
      end

      assert_equal 1, exit_error.status
    end

    assert_equal "", out
    assert_includes err, "ERROR:"
    assert_includes err, "--definitely-not-a-real-flag"
    assert_includes err, "See:"
  end
end

class CLIInitTest < Minitest::Test
  include CLITestHelpers

  def test_init_creates_schedule_file
    with_project_dir do
      status, out, err = run_cli(["init"])
      assert_equal 0, status
      assert_includes out, "Wrote schedule template"
      assert_equal "", err
      assert File.file?(File.join("config", "schedule.rb"))
    end
  end

  def test_init_refuses_overwrite_without_force
    with_project_dir do
      path = File.join("config", "schedule.rb")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "# existing\n")

      status, out, err = run_cli(["init"])
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "already exists"
    end
  end

  def test_init_overwrites_with_force
    with_project_dir do
      path = File.join("config", "schedule.rb")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "# existing\n")

      status, out, err = run_cli(["init", "--force"])
      assert_equal 0, status
      assert_includes out, "Overwrote schedule template"
      assert_equal "", err
      assert_includes File.read(path), "every \"5m\""
    end
  end

  def test_init_handles_filesystem_errors
    with_project_dir do
      FileUtils.mkdir_p("config")
      status, out, err = run_cli(["init", "--schedule", "config", "--force"])
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "Is a directory"
    end
  end

  def test_init_verbose_includes_error_details
    with_project_dir do
      FileUtils.mkdir_p("config")
      status, out, err = run_cli(["init", "--schedule", "config", "--force", "--verbose"])
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "Is a directory"
      assert_includes err, "lib/wheneverd/cli/init.rb"
    end
  end
end

class CLIShowTest < Minitest::Test
  include CLITestHelpers

  def test_show_renders_units_to_stdout
    with_project_dir do
      assert_equal 0, run_cli(["init"]).first
      status, out, err = run_cli(["show", "--identifier", "demo"])

      assert_equal 0, status
      assert_equal "", err
      assert_includes out, "OnUnitActiveSec=300"
      assert_includes out, "OnCalendar=hourly"
      assert_includes out, "OnCalendar=*-*-27..31 00:00:00"
      assert_includes out, "ExecStart=echo hello"
    end
  end

  def test_show_reports_missing_schedule_file
    with_project_dir do
      status, out, err = run_cli(["show"])
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "Schedule file not found"
      assert_includes err, "config/schedule.rb"
    end
  end
end

class CLIWriteTest < Minitest::Test
  include CLITestHelpers

  def test_write_creates_unit_files_in_unit_dir
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["init"]).first
      status, out, err = run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir])

      assert_equal 0, status
      assert_equal "", err
      assert_includes out, File.join(unit_dir, "wheneverd-demo-e0-j0.service")
      assert File.exist?(File.join(unit_dir, "wheneverd-demo-e0-j0.timer"))
    end
  end

  def test_write_dry_run_does_not_create_files
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["init"]).first
      status, out, err = run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir,
                                  "--dry-run"])

      assert_equal 0, status
      assert_equal "", err
      assert_includes out, File.join(unit_dir, "wheneverd-demo-e0-j0.timer")
      refute Dir.exist?(unit_dir)
    end
  end

  def test_write_reports_missing_schedule_file
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      status, out, err = run_cli(["write", "--unit-dir", unit_dir])
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "Schedule file not found"
    end
  end
end

class CLIDeleteTest < Minitest::Test
  include CLITestHelpers

  def test_delete_removes_units_for_identifier
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["init"]).first
      assert_equal 0, run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir]).first

      status, out, err = run_cli(["delete", "--identifier", "demo", "--unit-dir", unit_dir])
      assert_equal 0, status
      assert_equal "", err
      assert_includes out, File.join(unit_dir, "wheneverd-demo-e0-j0.timer")
      refute File.exist?(File.join(unit_dir, "wheneverd-demo-e0-j0.timer"))
    end
  end

  def test_delete_reports_invalid_identifier
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      FileUtils.mkdir_p(unit_dir)

      status, out, err = run_cli(["delete", "--identifier", "!!!", "--unit-dir", unit_dir])
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "identifier must include at least one alphanumeric character"
    end
  end
end

class CLIVerboseTest < Minitest::Test
  include CLITestHelpers

  def test_verbose_prints_error_details
    with_project_dir do
      status, out, err = run_cli(["show", "--verbose"])
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "Schedule file not found"
      assert_includes err, "lib/wheneverd/cli.rb"
    end
  end
end
