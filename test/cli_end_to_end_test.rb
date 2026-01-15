# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_subprocess_test_helpers"

class CLIEndToEndTest < Minitest::Test
  include CLISubprocessTestHelpers

  def test_init_show_write_current_delete_workflow_via_exe
    with_temp_project_dir do |project_dir|
      init_schedule(project_dir)
      show_units(project_dir)
      unit_dir = File.join(project_dir, "tmp_units")
      write_units(project_dir, unit_dir)
      current_units(project_dir, unit_dir)
      delete_units(project_dir, unit_dir)
    end
  end

  private

  def init_schedule(project_dir)
    status, out, err = run_exe(["init"], chdir: project_dir)
    assert_equal 0, status
    assert_equal "", err
    assert_includes out, "Wrote schedule template"
    assert File.file?(File.join(project_dir, "config", "schedule.rb"))
  end

  def show_units(project_dir)
    status, out, err = run_exe(["show", "--identifier", "demo"], chdir: project_dir)
    assert_equal 0, status
    assert_equal "", err
    assert_includes out, "OnActiveSec=300"
    assert_includes out, "OnUnitActiveSec=300"
    assert_includes out, "ExecStart=echo hello"
  end

  def write_units(project_dir, unit_dir)
    status, out, err = run_exe(
      ["write", "--identifier", "demo", "--unit-dir", unit_dir],
      chdir: project_dir
    )
    assert_equal 0, status
    assert_equal "", err
    assert_timer_unit_written(unit_dir, out)
    assert_timer_unit_contents(unit_dir)
  end

  def current_units(project_dir, unit_dir)
    status, out, err = run_exe(
      ["current", "--identifier", "demo", "--unit-dir", unit_dir],
      chdir: project_dir
    )
    assert_equal 0, status
    assert_equal "", err
    assert_includes out, "wheneverd-demo-e0-j0.timer"
    assert_includes out, Wheneverd::Systemd::Renderer::MARKER_PREFIX
  end

  def delete_units(project_dir, unit_dir)
    status, out, err = run_exe(
      ["delete", "--identifier", "demo", "--unit-dir", unit_dir],
      chdir: project_dir
    )
    assert_equal 0, status
    assert_equal "", err
    assert_includes out, File.join(unit_dir, "wheneverd-demo-e0-j0.timer")
    refute File.exist?(File.join(unit_dir, "wheneverd-demo-e0-j0.timer"))
  end

  def assert_timer_unit_written(unit_dir, out)
    assert_includes out, File.join(unit_dir, "wheneverd-demo-e0-j0.service")
    assert File.exist?(File.join(unit_dir, "wheneverd-demo-e0-j0.timer"))
  end

  def assert_timer_unit_contents(unit_dir)
    timer_contents = File.read(File.join(unit_dir, "wheneverd-demo-e0-j0.timer"))
    assert_includes timer_contents, Wheneverd::Systemd::Renderer::MARKER_PREFIX
    assert_includes timer_contents, "OnActiveSec=300"
    assert_includes timer_contents, "OnUnitActiveSec=300"
  end
end
