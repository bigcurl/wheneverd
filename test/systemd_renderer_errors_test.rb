# frozen_string_literal: true

require_relative "test_helper"

class SystemdRendererErrorsTest < Minitest::Test
  def test_rejects_empty_identifier
    assert_raises(Wheneverd::Systemd::InvalidIdentifierError) do
      Wheneverd::Systemd::Renderer.render(minimal_schedule, identifier: "  ")
    end
  end

  def test_rejects_identifier_without_alphanumeric_chars
    assert_raises(Wheneverd::Systemd::InvalidIdentifierError) do
      Wheneverd::Systemd::Renderer.render(minimal_schedule, identifier: "!!!")
    end
  end

  def test_sanitizes_identifier_into_unit_basename
    units = Wheneverd::Systemd::Renderer.render(minimal_schedule, identifier: "my app!")
    assert_includes units.map(&:path_basename), "wheneverd-my-app-e0-j0.timer"
  end

  def test_rejects_invalid_schedule_type
    assert_raises(ArgumentError) do
      Wheneverd::Systemd::Renderer.render(Object.new, identifier: "demo")
    end
  end

  def test_rejects_unsupported_trigger_type
    assert_raises(ArgumentError) do
      Wheneverd::Systemd::Renderer.render(schedule_with_trigger(Object.new), identifier: "demo")
    end
  end

  private

  def minimal_schedule
    Wheneverd::Schedule.new(
      entries: [
        Wheneverd::Entry.new(
          trigger: Wheneverd::Trigger::Interval.new(seconds: 60),
          jobs: [Wheneverd::Job::Command.new(command: "echo hi")]
        )
      ]
    )
  end

  def schedule_with_trigger(trigger)
    Wheneverd::Schedule.new(
      entries: [
        Wheneverd::Entry.new(
          trigger: trigger,
          jobs: [Wheneverd::Job::Command.new(command: "echo hi")]
        )
      ]
    )
  end
end
