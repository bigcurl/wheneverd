# frozen_string_literal: true

require_relative "test_helper"

class SystemdCalendarSpecTest < Minitest::Test
  def test_translates_base_calendar_specs
    assert_equal "hourly", Wheneverd::Systemd::CalendarSpec.to_on_calendar("hour")
    assert_equal "daily", Wheneverd::Systemd::CalendarSpec.to_on_calendar("day")
    assert_equal "monthly", Wheneverd::Systemd::CalendarSpec.to_on_calendar("month")
    assert_equal "yearly", Wheneverd::Systemd::CalendarSpec.to_on_calendar("year")
  end

  def test_translates_weekday_weekend_and_days_without_at_to_midnight
    assert_equal "Mon..Fri *-*-* 00:00:00", Wheneverd::Systemd::CalendarSpec.to_on_calendar("weekday")
    assert_equal "Sat,Sun *-*-* 00:00:00", Wheneverd::Systemd::CalendarSpec.to_on_calendar("weekend")
    assert_equal "Mon *-*-* 00:00:00", Wheneverd::Systemd::CalendarSpec.to_on_calendar("monday")
  end

  def test_translates_calendar_specs_with_at
    assert_equal "*-*-* 04:30:00", Wheneverd::Systemd::CalendarSpec.to_on_calendar("day@4:30 am")
    assert_equal "Mon..Fri *-*-* 00:15:00", Wheneverd::Systemd::CalendarSpec.to_on_calendar("weekday@00:15")
    assert_equal "Sat,Sun *-*-* 18:00:00",
                 Wheneverd::Systemd::CalendarSpec.to_on_calendar("weekend@6:00 pm")
  end

  def test_rejects_invalid_calendar_specs
    assert_raises(Wheneverd::Systemd::InvalidCalendarSpecError) do
      Wheneverd::Systemd::CalendarSpec.to_on_calendar("")
    end

    assert_raises(Wheneverd::Systemd::InvalidCalendarSpecError) do
      Wheneverd::Systemd::CalendarSpec.to_on_calendar("not-a-period")
    end

    assert_raises(Wheneverd::Systemd::InvalidCalendarSpecError) do
      Wheneverd::Systemd::CalendarSpec.to_on_calendar("hour@12pm")
    end
  end
end
