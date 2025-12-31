# frozen_string_literal: true

module Wheneverd
  module Systemd
    module CronParser
      def self.to_on_calendar(cron_5_fields)
        input = cron_5_fields.to_s.strip
        minute_str, hour_str, dom_str, month_str, dow_str = split_fields(input)

        minute = parse_int_field(minute_str, 0..59, field: "minute", input: input)
        hour = parse_int_field(hour_str, 0..23, field: "hour", input: input)

        validate_month_and_dow(month_str, dow_str, input: input)

        "#{date_part(dom_str, input: input)} #{time_part(hour, minute)}"
      end

      def self.split_fields(input)
        parts = input.split(/\s+/)
        validate_parts_length(parts, input: input)

        parts
      end
      private_class_method :split_fields

      def self.validate_parts_length(parts, input:)
        return if parts.length == 5

        raise UnsupportedCronError, "Unsupported cron #{input.inspect}: expected 5 fields"
      end
      private_class_method :validate_parts_length

      def self.validate_month_and_dow(month_str, dow_str, input:)
        unless month_str == "*"
          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: month must be \"*\""
        end
        return if dow_str == "*"

        raise UnsupportedCronError, "Unsupported cron #{input.inspect}: day-of-week must be \"*\""
      end
      private_class_method :validate_month_and_dow

      def self.date_part(dom_str, input:)
        "*-*-#{dom_to_systemd(dom_str, input: input)}"
      end
      private_class_method :date_part

      def self.time_part(hour, minute)
        format("%<hour>02d:%<minute>02d:00", hour: hour, minute: minute)
      end
      private_class_method :time_part

      def self.parse_int_field(str, range, field:, input:)
        unless /\A\d+\z/.match?(str)
          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: #{field} must be a number"
        end

        value = Integer(str, 10)
        unless range.cover?(value)
          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: #{field} out of range"
        end

        value
      end
      private_class_method :parse_int_field

      def self.dom_to_systemd(dom_str, input:)
        return "*" if dom_str == "*"

        return dom_number_to_systemd(dom_str, input: input) if /\A\d+\z/.match?(dom_str)

        if (match = /\A(?<start>\d+)-(?<finish>\d+)\z/.match(dom_str))
          return dom_range_to_systemd(match, input: input)
        end

        raise UnsupportedCronError,
              "Unsupported cron #{input.inspect}: unsupported day-of-month field"
      end
      private_class_method :dom_to_systemd

      def self.dom_number_to_systemd(dom_str, input:)
        dom = Integer(dom_str, 10)
        return dom_str if dom.between?(1, 31)

        raise UnsupportedCronError, "Unsupported cron #{input.inspect}: day-of-month out of range"
      end
      private_class_method :dom_number_to_systemd

      def self.dom_range_to_systemd(match, input:)
        start_dom = Integer(match[:start], 10)
        finish_dom = Integer(match[:finish], 10)

        unless start_dom.between?(1, 31) && finish_dom.between?(1, 31) && start_dom <= finish_dom
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: invalid day-of-month range"
        end

        "#{start_dom}..#{finish_dom}"
      end
      private_class_method :dom_range_to_systemd
    end
  end
end
