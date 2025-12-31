# frozen_string_literal: true

require_relative "test_helper"

class SystemdTimeParserTest < Minitest::Test
  def test_parses_12h_times
    assert_equal "04:30:00", Wheneverd::Systemd::TimeParser.parse("4:30 am")
    assert_equal "18:00:00", Wheneverd::Systemd::TimeParser.parse("6:00 pm")
    assert_equal "12:00:00", Wheneverd::Systemd::TimeParser.parse("12pm")
    assert_equal "00:00:00", Wheneverd::Systemd::TimeParser.parse("12 am")
  end

  def test_parses_24h_times
    assert_equal "00:15:00", Wheneverd::Systemd::TimeParser.parse("00:15")
    assert_equal "23:59:59", Wheneverd::Systemd::TimeParser.parse("23:59:59")
  end

  def test_rejects_invalid_times
    assert_raises(Wheneverd::Systemd::InvalidTimeError) { Wheneverd::Systemd::TimeParser.parse("") }
    assert_raises(Wheneverd::Systemd::InvalidTimeError) { Wheneverd::Systemd::TimeParser.parse("25:00") }
    assert_raises(Wheneverd::Systemd::InvalidTimeError) { Wheneverd::Systemd::TimeParser.parse("12:99") }
    assert_raises(Wheneverd::Systemd::InvalidTimeError) { Wheneverd::Systemd::TimeParser.parse("0pm") }
    assert_raises(Wheneverd::Systemd::InvalidTimeError) { Wheneverd::Systemd::TimeParser.parse("nope") }
  end
end
