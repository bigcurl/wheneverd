# frozen_string_literal: true

require_relative "test_helper"

class SystemdCronParserTest < Minitest::Test
  def test_translates_supported_cron
    assert_equal "*-*-27..31 00:00:00",
                 Wheneverd::Systemd::CronParser.to_on_calendar("0 0 27-31 * *")
    assert_equal "*-*-* 00:00:00", Wheneverd::Systemd::CronParser.to_on_calendar("0 0 * * *")
    assert_equal "*-*-5 23:59:00", Wheneverd::Systemd::CronParser.to_on_calendar("59 23 5 * *")
  end

  def test_rejects_unsupported_cron_patterns
    assert_unsupported(
      "0 0",
      "x 0 * * *",
      "60 0 * * *",
      "0 0 0 * *",
      "0 0 10 1 *",
      "0 0 10 * Mon",
      "0 0 31-27 * *",
      "0 0 */2 * *"
    )
  end

  private

  def assert_unsupported(*crons)
    crons.each do |cron|
      assert_raises(Wheneverd::Systemd::UnsupportedCronError) { Wheneverd::Systemd::CronParser.to_on_calendar(cron) }
    end
  end
end
