# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class SystemdUnitDeleterTest < Minitest::Test
  def test_delete_rejects_invalid_identifier
    Dir.mktmpdir("wheneverd-") do |dir|
      assert_raises(Wheneverd::Systemd::InvalidIdentifierError) do
        Wheneverd::Systemd::UnitDeleter.delete(identifier: "!!!", unit_dir: dir)
      end
    end
  end

  def test_delete_deletes_only_generated_files_for_identifier
    with_written_units do |unit_dir, written_paths|
      create_non_generated_match(unit_dir, "demo")
      deleted = Wheneverd::Systemd::UnitDeleter.delete(identifier: "demo", unit_dir: unit_dir)
      assert_equal written_paths.sort, deleted.sort
      written_paths.each { |p| refute File.exist?(p) }
      assert File.exist?(File.join(unit_dir, "wheneverd-demo-e999-j999.timer"))
    end
  end

  def test_delete_does_not_delete_other_identifier_or_non_matching_files
    with_written_units do |unit_dir, _written_paths|
      create_generated_different_identifier(unit_dir)
      File.write(File.join(unit_dir, "other.timer"), "#{marker_line}\n")
      Wheneverd::Systemd::UnitDeleter.delete(identifier: "demo", unit_dir: unit_dir)
      assert File.exist?(File.join(unit_dir, "wheneverd-other-e0-j0.timer"))
      assert File.exist?(File.join(unit_dir, "other.timer"))
    end
  end

  def test_delete_dry_run_does_not_remove_files
    with_written_units do |unit_dir, written_paths|
      deleted = Wheneverd::Systemd::UnitDeleter.delete(identifier: "demo", unit_dir: unit_dir,
                                                       dry_run: true)
      assert_equal written_paths.sort, deleted.sort
      written_paths.each { |p| assert File.exist?(p) }
    end
  end

  private

  def with_written_units
    Dir.mktmpdir("wheneverd-") do |dir|
      unit_dir = File.join(dir, "systemd", "user")
      written_paths = Wheneverd::Systemd::UnitWriter.write(demo_units, unit_dir: unit_dir)
      yield unit_dir, written_paths
    end
  end

  def demo_units
    Wheneverd::Systemd::Renderer.render(schedule_with_interval_job("echo hello"),
                                        identifier: "demo")
  end

  def schedule_with_interval_job(command)
    Wheneverd::Schedule.new(
      entries: [
        Wheneverd::Entry.new(
          trigger: Wheneverd::Trigger::Interval.new(seconds: 60),
          jobs: [Wheneverd::Job::Command.new(command: command)]
        )
      ]
    )
  end

  def marker_line
    "#{Wheneverd::Systemd::Renderer::MARKER_PREFIX} #{Wheneverd::VERSION}; do not edit."
  end

  def create_non_generated_match(unit_dir, identifier)
    path = File.join(unit_dir, "wheneverd-#{identifier}-e999-j999.timer")
    File.write(path, "[Timer]\nOnCalendar=daily\n")
  end

  def create_generated_different_identifier(unit_dir)
    path = File.join(unit_dir, "wheneverd-other-e0-j0.timer")
    File.write(path, "#{marker_line}\n[Timer]\nOnCalendar=daily\n")
  end
end
