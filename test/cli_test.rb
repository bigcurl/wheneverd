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

  EXPECTED_SHOW_OUTPUT_SNIPPETS = [
    "OnActiveSec=300",
    "OnUnitActiveSec=300",
    "OnCalendar=hourly",
    "OnCalendar=*-*-27..31 00:00:00",
    "ExecStart=echo hello"
  ].freeze

  def test_show_renders_units_to_stdout
    with_project_dir do
      assert_equal 0, run_cli(["init"]).first
      status, out, err = run_cli(["show", "--identifier", "demo"])

      assert_equal 0, status
      assert_equal "", err
      EXPECTED_SHOW_OUTPUT_SNIPPETS.each { |expected| assert_includes out, expected }
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
      status, out, err = run_write(unit_dir)

      assert_cli_success(status, err)
      assert_first_job_written(unit_dir, out)
    end
  end

  def test_write_dry_run_does_not_create_files
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      assert_equal 0, run_cli(["init"]).first
      status, out, err = run_write(unit_dir, "--dry-run")

      assert_equal 0, status
      assert_equal "", err
      assert_includes out, File.join(unit_dir, expected_timer_basenames.fetch(0))
      refute Dir.exist?(unit_dir)
    end
  end

  def test_write_prunes_old_units_by_default
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      units1 = write_schedule_and_expected_units(schedule_with_two_jobs)
      write_and_assert_success(unit_dir)
      assert_unit_files_present(unit_dir, units1)
      units2 = write_schedule_and_expected_units(schedule_with_one_job)
      write_and_assert_success(unit_dir)
      assert_unit_files_pruned(unit_dir, units_before: units1, units_after: units2)
    end
  end

  def test_write_no_prune_keeps_old_units
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      units1 = write_schedule_and_expected_units(schedule_with_two_jobs)

      status, _out, err = run_write(unit_dir)
      assert_cli_success(status, err)

      write_schedule(schedule_with_one_job)
      status, _out, err = run_write(unit_dir, "--no-prune")
      assert_cli_success(status, err)

      assert_unit_files_present(unit_dir, units1)
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

  def write_schedule(contents)
    path = File.join("config", "schedule.rb")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
  end

  def schedule_with_two_jobs
    <<~RUBY
      # frozen_string_literal: true

      every "1m" do
        command "echo a"
      end

      every "2m" do
        command "echo b"
      end
    RUBY
  end

  def schedule_with_one_job
    <<~RUBY
      # frozen_string_literal: true

      every "1m" do
        command "echo a"
      end
    RUBY
  end

  private

  def run_write(unit_dir, *extra_args)
    run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir, *extra_args])
  end

  def assert_first_job_written(unit_dir, out)
    assert_includes out, File.join(unit_dir, expected_service_basenames.fetch(0))
    assert File.exist?(File.join(unit_dir, expected_timer_basenames.fetch(0)))
  end

  def write_schedule_and_expected_units(contents)
    write_schedule(contents)
    expected_units(identifier: "demo")
  end

  def assert_unit_files_present(unit_dir, units)
    units.each { |unit| assert File.exist?(File.join(unit_dir, unit.path_basename)) }
  end

  def assert_unit_files_pruned(unit_dir, units_before:, units_after:)
    keep = units_after.map(&:path_basename)
    stale = units_before.map(&:path_basename) - keep

    keep.each { |basename| assert File.exist?(File.join(unit_dir, basename)) }
    stale.each { |basename| refute File.exist?(File.join(unit_dir, basename)) }
  end

  def write_and_assert_success(unit_dir, *extra_args)
    status, _out, err = run_write(unit_dir, *extra_args)
    assert_cli_success(status, err)
  end
end

class CLIDeleteTest < Minitest::Test
  include CLITestHelpers

  def test_delete_removes_units_for_identifier
    with_project_dir do |project_dir|
      unit_dir = File.join(project_dir, "tmp_units")
      init_template_schedule
      write_demo_units(unit_dir)

      status, out, err = delete_demo_units(unit_dir)
      assert_cli_success(status, err)
      assert_demo_timer_deleted(unit_dir, out)
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

  private

  def init_template_schedule
    assert_equal 0, run_cli(["init"]).first
  end

  def write_demo_units(unit_dir)
    assert_equal 0, run_cli(["write", "--identifier", "demo", "--unit-dir", unit_dir]).first
  end

  def delete_demo_units(unit_dir)
    run_cli(["delete", "--identifier", "demo", "--unit-dir", unit_dir])
  end

  def assert_demo_timer_deleted(unit_dir, out)
    expected_timer = expected_timer_basenames.fetch(0)
    expected_timer_path = File.join(unit_dir, expected_timer)
    assert_includes out, expected_timer_path
    refute File.exist?(expected_timer_path)
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
