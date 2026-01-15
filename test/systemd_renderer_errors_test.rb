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
    matched = units.map(&:path_basename).any? do |basename|
      /\Awheneverd-my-app-[0-9a-f]{12}\.timer\z/.match?(basename)
    end
    assert matched
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

  def test_rejects_unsupported_job_type
    schedule = schedule_with_job(Object.new)
    assert_raises(ArgumentError) do
      Wheneverd::Systemd::Renderer.render(schedule, identifier: "demo")
    end
  end

  def test_timer_lines_for_rejects_unknown_trigger
    assert_raises(ArgumentError) do
      Wheneverd::Systemd::Renderer.send(:timer_lines_for, Object.new)
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

  def schedule_with_job(job)
    Wheneverd::Schedule.new(
      entries: [
        Wheneverd::Entry.new(
          trigger: Wheneverd::Trigger::Interval.new(seconds: 60),
          jobs: [job]
        )
      ]
    )
  end
end
