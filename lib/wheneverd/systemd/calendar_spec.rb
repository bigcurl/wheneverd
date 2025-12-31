# frozen_string_literal: true

module Wheneverd
  module Systemd
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

      def self.to_on_calendar(spec)
        input = spec.to_s.strip
        raise InvalidCalendarSpecError, "Invalid calendar spec: empty" if input.empty?

        return cron_to_on_calendar(input) if input.start_with?("cron:")

        base, at = input.split("@", 2)
        base = base.strip

        raise InvalidCalendarSpecError, "Invalid calendar spec: #{input.inspect}" if base.empty?

        translate_base_with_optional_at(base, at)
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

      def self.cron_to_on_calendar(input)
        cron = input.delete_prefix("cron:")
        Wheneverd::Systemd::CronParser.to_on_calendar(cron)
      end
      private_class_method :cron_to_on_calendar

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
