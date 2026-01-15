# frozen_string_literal: true

require_relative "test_helper"

class SystemdCronParserTest < Minitest::Test
  def test_translates_simple_cron_to_single_value
    assert_values("0 0 * * *", ["*-*-* 00:00:00"])
    assert_values("59 23 5 * *", ["*-*-5 23:59:00"])
    assert_values("0 0 27-31 * *", ["*-*-27..31 00:00:00"])
  end

  def test_translates_months_and_steps
    assert_values("0 0 * 1 *", ["*-1-* 00:00:00"])
    assert_values("0 0 * Jan *", ["*-1-* 00:00:00"])
    assert_values("*/15 9-17 * * *", ["*-*-* 09..17:00/15:00"])
  end

  def test_translates_lists_and_steps
    assert_values("0,30 8,16 * * *", ["*-*-* 08,16:00,30:00"])
    assert_values("0 0 */2 * *", ["*-*-1/2 00:00:00"])
    assert_values("0 0 * */2 *", ["*-1/2-* 00:00:00"])
  end

  def test_translates_day_of_week_variants
    assert_values("0 0 * * Mon", ["Mon *-*-* 00:00:00"])
    assert_values("0 0 * * 1-5", ["Mon..Fri *-*-* 00:00:00"])
    assert_values("0 0 * * */2", ["Tue,Thu,Sat..Sun *-*-* 00:00:00"])
    assert_values("0 0 * * Fri-Mon", ["Mon,Fri..Sun *-*-* 00:00:00"])
  end

  def test_dom_and_dow_or_semantics_expands_to_multiple_values
    assert_values("0 0 1 * Mon", ["Mon *-*-* 00:00:00", "*-*-1 00:00:00"])
  end

  def test_to_on_calendar_rejects_multiple_values
    assert_raises(Wheneverd::Systemd::UnsupportedCronError) do
      Wheneverd::Systemd::CronParser.to_on_calendar("0 0 1 * Mon")
    end
  end

  def test_private_helpers_reject_empty_numeric_field
    assert_private_unsupported(
      :parse_mapped_numeric_expression,
      "",
      0..59,
      field: "minute",
      input: "x",
      names: {}
    )
  end

  def test_private_helpers_reject_invalid_numeric_tokens
    common = { field: "minute", input: "x", names: {} }
    assert_private_unsupported(:parse_mapped_value, " ", 0..59, **common)
    assert_private_unsupported(:parse_positive_int, "x", field: "minute", input: "x", label: "step")
  end

  def test_private_helpers_reject_empty_dow_and_invalid_tokens
    assert_private_unsupported(:parse_dow_set, "", input: "x")
    assert_private_unsupported(:apply_dow_part, Array.new(7, false), "", input: "x")
    assert_private_unsupported(:parse_dow_value, "", input: "x")
    assert_private_unsupported(:parse_dow_value, "8", input: "x")
  end

  def test_rejects_unsupported_cron_patterns
    assert_unsupported(
      "0 0",
      "x 0 * * *",
      "60 0 * * *",
      "0 0 0 * *",
      "0 0 10 13 *"
    )
  end

  def test_rejects_unsupported_cron_tokens
    assert_unsupported(
      "0 0 31-27 * *",
      "0 0 * * Funday",
      "0 0 */0 * *",
      "0 0 ? * *"
    )
  end

  def test_rejects_empty_tokens_and_invalid_steps
    assert_unsupported(
      "0,,15 0 * * *",
      "*/x 0 * * *",
      "0 0 * * Mon,,Tue",
      "0 0 * * Mon-",
      "0 0 * * 8"
    )
  end

  private

  def assert_values(cron, expected)
    assert_equal expected, Wheneverd::Systemd::CronParser.to_on_calendar_values(cron)
  end

  def assert_private_unsupported(method, *args, **kwargs)
    parser = Wheneverd::Systemd::CronParser
    assert_raises(Wheneverd::Systemd::UnsupportedCronError) do
      parser.send(method, *args, **kwargs)
    end
  end

  def assert_unsupported(*crons)
    crons.each do |cron|
      assert_raises(Wheneverd::Systemd::UnsupportedCronError) do
        Wheneverd::Systemd::CronParser.to_on_calendar_values(cron)
      end
    end
  end
end
