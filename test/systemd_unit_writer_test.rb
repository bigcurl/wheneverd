# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class SystemdUnitWriterTest < Minitest::Test
  def test_write_creates_directory
    with_unit_dir do |unit_dir|
      refute Dir.exist?(unit_dir)
      Wheneverd::Systemd::UnitWriter.write(demo_units, unit_dir: unit_dir)
      assert Dir.exist?(unit_dir)
    end
  end

  def test_write_returns_full_paths_in_unit_order
    with_unit_dir do |unit_dir|
      units = demo_units
      paths = Wheneverd::Systemd::UnitWriter.write(units, unit_dir: unit_dir)
      assert_equal expected_paths(unit_dir, units), paths
    end
  end

  def test_write_writes_expected_contents
    with_unit_dir do |unit_dir|
      units = demo_units
      Wheneverd::Systemd::UnitWriter.write(units, unit_dir: unit_dir)
      units.each { |u| assert_equal u.contents, File.read(File.join(unit_dir, u.path_basename)) }
    end
  end

  def test_write_dry_run_does_not_create_dir_or_files
    with_unit_dir do |unit_dir|
      paths = Wheneverd::Systemd::UnitWriter.write(units, unit_dir: unit_dir, dry_run: true)
      assert_equal expected_paths(unit_dir, units), paths
      refute Dir.exist?(unit_dir)
    end
  end

  private

  def units
    @units ||= demo_units
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

  def with_unit_dir
    Dir.mktmpdir("wheneverd-") do |dir|
      unit_dir = File.join(dir, "systemd", "user")
      yield unit_dir
    end
  end

  def expected_paths(unit_dir, units)
    units.map { |u| File.join(unit_dir, u.path_basename) }
  end
end
