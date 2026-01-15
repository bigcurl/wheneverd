# frozen_string_literal: true

require_relative "test_helper"
require "tmpdir"

class SystemdUnitWriterPruneTest < Minitest::Test
  def test_write_prune_rejects_invalid_identifier
    with_unit_dir do |unit_dir|
      assert_raises(Wheneverd::Systemd::InvalidIdentifierError) do
        Wheneverd::Systemd::UnitWriter.write(
          [],
          unit_dir: unit_dir,
          prune: true,
          identifier: "!!!"
        )
      end
    end
  end

  def test_write_prune_removes_stale_units
    with_unit_dir do |unit_dir|
      units1 = rendered_units_for_commands(["echo a", "echo b"])
      write_units(unit_dir, units1, prune: true)

      units2 = rendered_units_for_commands(["echo a"])
      write_units(unit_dir, units2, prune: true)

      assert_unit_files_pruned(unit_dir, units_before: units1, units_after: units2)
    end
  end

  def test_write_no_prune_keeps_stale_units
    with_unit_dir do |unit_dir|
      units1 = rendered_units_for_commands(["echo a", "echo b"])
      Wheneverd::Systemd::UnitWriter.write(units1, unit_dir: unit_dir)

      units2 = rendered_units_for_commands(["echo a"])
      write_units(unit_dir, units2, prune: false)

      assert_unit_files_present(unit_dir, units1)
    end
  end

  private

  def rendered_units_for_commands(commands)
    schedule = Wheneverd::Schedule.new(
      entries: commands.map do |command|
        Wheneverd::Entry.new(
          trigger: Wheneverd::Trigger::Interval.new(seconds: 60),
          jobs: [Wheneverd::Job::Command.new(command: command)]
        )
      end
    )
    Wheneverd::Systemd::Renderer.render(schedule, identifier: "demo")
  end

  def write_units(unit_dir, units, prune:)
    Wheneverd::Systemd::UnitWriter.write(
      units,
      unit_dir: unit_dir,
      prune: prune,
      identifier: "demo"
    )
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

  def with_unit_dir
    Dir.mktmpdir("wheneverd-") do |dir|
      unit_dir = File.join(dir, "systemd", "user")
      yield unit_dir
    end
  end
end
