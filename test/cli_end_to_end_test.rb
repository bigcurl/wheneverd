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
    assert_match(/wheneverd-demo-[0-9a-f]{12}\.timer/, out)
    assert_includes out, Wheneverd::Systemd::Renderer::MARKER_PREFIX
  end

  def delete_units(project_dir, unit_dir)
    status, out, err = run_exe(
      ["delete", "--identifier", "demo", "--unit-dir", unit_dir],
      chdir: project_dir
    )
    assert_equal 0, status
    assert_equal "", err
    timer_path = out.lines.map(&:strip).find { |line| line.end_with?(".timer") }
    assert timer_path, "expected delete to print at least one *.timer path"
    assert_includes timer_path, unit_dir
    refute File.exist?(timer_path)
  end

  def assert_timer_unit_written(unit_dir, out)
    service_path = out.lines.map(&:strip).find { |line| line.end_with?(".service") }
    timer_path = out.lines.map(&:strip).find { |line| line.end_with?(".timer") }
    assert service_path, "expected write to print at least one *.service path"
    assert timer_path, "expected write to print at least one *.timer path"
    assert_includes service_path, unit_dir
    assert_includes timer_path, unit_dir
    assert File.exist?(timer_path)
  end

  def assert_timer_unit_contents(unit_dir)
    timer_basenames = Dir.children(unit_dir).select { |b| b.end_with?(".timer") }
    assert timer_basenames.any?, "expected unit_dir to contain at least one *.timer file"

    timer_contents = timer_basenames.filter_map do |basename|
      contents = File.read(File.join(unit_dir, basename))
      contents if contents.include?("OnActiveSec=300")
    end.first

    assert timer_contents, "expected at least one interval timer with OnActiveSec=300"
    assert_includes timer_contents, Wheneverd::Systemd::Renderer::MARKER_PREFIX
    assert_includes timer_contents, "OnActiveSec=300"
    assert_includes timer_contents, "OnUnitActiveSec=300"
  end
end
