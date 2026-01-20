# frozen_string_literal: true

require_relative "cron_parser/field_parser"
require_relative "cron_parser/dow_parser"

module Wheneverd
  module Systemd
    # Converts 5-field cron expressions into systemd `OnCalendar=` specs.
    #
    # Uses {FieldParser} for parsing numeric fields (minute, hour, day-of-month, month)
    # and {DowParser} for day-of-week parsing and formatting.
    module CronParser
      MONTH_NAMES = {
        "jan" => 1,
        "feb" => 2,
        "mar" => 3,
        "apr" => 4,
        "may" => 5,
        "jun" => 6,
        "jul" => 7,
        "aug" => 8,
        "sep" => 9,
        "oct" => 10,
        "nov" => 11,
        "dec" => 12
      }.freeze

      # @param cron_5_fields [String]
      # @return [Array<String>] systemd `OnCalendar=` values
      # @raise [Wheneverd::Systemd::UnsupportedCronError]
      def self.to_on_calendar_values(cron_5_fields)
        input = cron_5_fields.to_s.strip
        fields = split_fields(input)

        parsed = parse_all_fields(fields, input)
        format_on_calendar_values(parsed)
      end

      # @param cron_5_fields [String]
      # @return [String] systemd `OnCalendar=` value (only when cron translates to a single value)
      # @raise [Wheneverd::Systemd::UnsupportedCronError]
      def self.to_on_calendar(cron_5_fields)
        values = to_on_calendar_values(cron_5_fields)
        return values.fetch(0) if values.length == 1

        message =
          "Unsupported cron #{cron_5_fields.to_s.strip.inspect}: " \
          "requires multiple OnCalendar values"
        raise UnsupportedCronError, message
      end

      ParsedFields = Struct.new(:minute, :hour, :dom, :month, :dow_set, keyword_init: true)

      def self.split_fields(input)
        parts = input.split(/\s+/)
        unless parts.length == 5
          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: expected 5 fields"
        end

        parts
      end
      private_class_method :split_fields

      def self.parse_all_fields(fields, input)
        minute_str, hour_str, dom_str, month_str, dow_str = fields

        ParsedFields.new(
          minute: FieldParser.parse_numeric(minute_str, 0..59, field: "minute", input: input,
                                                               pad: 2),
          hour: FieldParser.parse_numeric(hour_str, 0..23, field: "hour", input: input, pad: 2),
          dom: FieldParser.parse_numeric(dom_str, 1..31, field: "day-of-month", input: input,
                                                         pad: 0),
          month: FieldParser.parse_mapped(month_str, 1..12, field: "month", input: input,
                                                            names: MONTH_NAMES),
          dow_set: DowParser.parse(dow_str, input: input)
        )
      end
      private_class_method :parse_all_fields

      def self.format_on_calendar_values(parsed)
        time = "#{parsed.hour}:#{parsed.minute}:00"
        dom_any = parsed.dom == "*"
        month_any = parsed.month == "*"

        date = "*-#{month_any ? '*' : parsed.month}-#{dom_any ? '*' : parsed.dom}"

        if parsed.dow_set.nil? && dom_any
          return ["*-#{month_any ? '*' : parsed.month}-* #{time}"]
        end

        values = []

        if parsed.dow_set
          dow = DowParser.format(parsed.dow_set)
          values << "#{dow} *-#{month_any ? '*' : parsed.month}-* #{time}"
        end

        values << "#{date} #{time}" unless dom_any

        values
      end
      private_class_method :format_on_calendar_values
    end
  end
end
