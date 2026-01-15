# frozen_string_literal: true

require_relative "test_helper"

class DSLCalendarSymbolPeriodListTest < Minitest::Test
  def test_validate_raises_when_not_array
    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) do
      Wheneverd::DSL::CalendarSymbolPeriodList.validate(
        "day",
        allowed_symbols: [:day],
        path: "x.rb"
      )
    end
    assert_includes error.message, "non-empty Array"
  end

  def test_validate_raises_when_empty_array
    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) do
      Wheneverd::DSL::CalendarSymbolPeriodList.validate(
        [],
        allowed_symbols: [:day],
        path: "x.rb"
      )
    end
    assert_includes error.message, "non-empty Array"
  end

  def test_validate_raises_when_array_contains_non_symbols
    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) do
      Wheneverd::DSL::CalendarSymbolPeriodList.validate([:day, "hour"], allowed_symbols: [:day],
                                                                        path: "x.rb")
    end
    assert_includes error.message, "must be Symbols"
  end

  def test_validate_raises_when_symbols_are_unknown
    error = assert_raises(Wheneverd::DSL::InvalidPeriodError) do
      Wheneverd::DSL::CalendarSymbolPeriodList.validate(%i[day nope nope], allowed_symbols: [:day],
                                                                           path: "x.rb")
    end
    assert_includes error.message, "Unknown period symbol"
    assert_includes error.message, ":nope"
  end

  def test_validate_returns_periods_when_valid
    result = Wheneverd::DSL::CalendarSymbolPeriodList.validate(
      %i[day day],
      allowed_symbols: [:day],
      path: "x.rb"
    )
    assert_equal %i[day day], result
  end
end
