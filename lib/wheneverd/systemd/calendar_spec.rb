# frozen_string_literal: true

module Wheneverd
  module Systemd
    # Translates higher-level schedule period specs into systemd `OnCalendar=` values.
    #
    # The DSL produces values like `"day@4:30 am"` or `"cron:0 0 27-31 * *"`, which are normalized
    # here into systemd-friendly calendar expressions.
    module CalendarSpec
      BASE_ALIASES = {
        "hour" => "hourly",
        "day" => "daily",
        "month" => "monthly",
        "year" => "yearly"
      }.freeze

      PREFIXES = {
        "day" => "*-*-*",
        "weekday" => "Mon..Fri *-*-*",
        "weekend" => "Sat,Sun *-*-*"
      }.freeze

      WEEKDAYS = {
        "monday" => "Mon",
        "tuesday" => "Tue",
        "wednesday" => "Wed",
        "thursday" => "Thu",
        "friday" => "Fri",
        "saturday" => "Sat",
        "sunday" => "Sun"
      }.freeze

      # Convert a calendar spec into a systemd `OnCalendar=` value.
      #
      # @param spec [String]
      # @return [String]
      # @raise [Wheneverd::Systemd::InvalidCalendarSpecError]
      def self.to_on_calendar(spec)
        values = to_on_calendar_values(spec)
        return values.fetch(0) if values.length == 1

        message =
          "Invalid calendar spec: #{spec.to_s.strip.inspect} " \
          "expands to multiple OnCalendar values"
        raise InvalidCalendarSpecError, message
      end

      # Convert a calendar spec into one or more systemd `OnCalendar=` values.
      #
      # Some inputs (e.g., certain cron expressions) may require multiple `OnCalendar=` entries
      # to preserve semantics.
      #
      # @param spec [String]
      # @return [Array<String>]
      # @raise [Wheneverd::Systemd::InvalidCalendarSpecError]
      def self.to_on_calendar_values(spec)
        input = spec.to_s.strip
        raise InvalidCalendarSpecError, "Invalid calendar spec: empty" if input.empty?

        return cron_to_on_calendar_values(input) if input.start_with?("cron:")

        base, at = input.split("@", 2)
        base = base.strip

        raise InvalidCalendarSpecError, "Invalid calendar spec: #{input.inspect}" if base.empty?

        [translate_base_with_optional_at(base, at)]
      end

      def self.translate_base_with_optional_at(base, at)
        return base_to_systemd(base) if at.nil?

        time = Wheneverd::Systemd::TimeParser.parse(at)
        "#{time_prefix_for_at(base)} #{time}"
      end
      private_class_method :translate_base_with_optional_at

      def self.base_to_systemd(base)
        return BASE_ALIASES.fetch(base) if BASE_ALIASES.key?(base)

        "#{time_prefix_for_midnight(base)} 00:00:00"
      end
      private_class_method :base_to_systemd

      def self.cron_to_on_calendar_values(input)
        cron = input.delete_prefix("cron:")
        Wheneverd::Systemd::CronParser.to_on_calendar_values(cron)
      end
      private_class_method :cron_to_on_calendar_values

      def self.time_prefix_for_at(base)
        return PREFIXES.fetch(base) if PREFIXES.key?(base)
        return "#{WEEKDAYS.fetch(base)} *-*-*" if WEEKDAYS.key?(base)

        raise InvalidCalendarSpecError,
              "Invalid calendar spec: #{base.inspect} does not support @time"
      end
      private_class_method :time_prefix_for_at

      def self.time_prefix_for_midnight(base)
        return PREFIXES.fetch(base) if PREFIXES.key?(base)
        return "#{WEEKDAYS.fetch(base)} *-*-*" if WEEKDAYS.key?(base)

        raise InvalidCalendarSpecError, "Invalid calendar spec: #{base.inspect}"
      end
      private_class_method :time_prefix_for_midnight
    end
  end
end
