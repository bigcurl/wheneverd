# frozen_string_literal: true

module Wheneverd
  module Systemd
    # Converts 5-field cron expressions into systemd `OnCalendar=` specs.
    module CronParser
      # @param cron_5_fields [String]
      # @return [Array<String>] systemd `OnCalendar=` values
      # @raise [Wheneverd::Systemd::UnsupportedCronError]
      def self.to_on_calendar_values(cron_5_fields)
        input = cron_5_fields.to_s.strip
        minute_str, hour_str, dom_str, month_str, dow_str = split_fields(input)

        minute = parse_numeric_expression(minute_str, 0..59, field: "minute", input: input, pad: 2)
        hour = parse_numeric_expression(hour_str, 0..23, field: "hour", input: input, pad: 2)
        dom = parse_numeric_expression(dom_str, 1..31, field: "day-of-month", input: input, pad: 0)
        month = parse_month_expression(month_str, input: input)
        dow_set = parse_dow_set(dow_str, input: input)

        time = "#{hour}:#{minute}:00"
        dom_any = dom == "*"
        month_any = month == "*"

        date = "*-#{month_any ? '*' : month}-#{dom_any ? '*' : dom}"

        if dow_set.nil? && dom_any
          return ["*-#{month_any ? '*' : month}-* #{time}"]
        end

        values = []

        if dow_set
          dow = format_dow_set(dow_set)
          values << "#{dow} *-#{month_any ? '*' : month}-* #{time}"
        end

        values << "#{date} #{time}" unless dom_any

        values
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

      DOW_NAMES = {
        "sun" => 0,
        "mon" => 1,
        "tue" => 2,
        "wed" => 3,
        "thu" => 4,
        "fri" => 5,
        "sat" => 6
      }.freeze

      DOW_SYSTEMD = {
        0 => "Sun",
        1 => "Mon",
        2 => "Tue",
        3 => "Wed",
        4 => "Thu",
        5 => "Fri",
        6 => "Sat"
      }.freeze

      DOW_ORDER = [1, 2, 3, 4, 5, 6, 0].freeze

      def self.parse_month_expression(month_str, input:)
        parse_mapped_numeric_expression(
          month_str,
          1..12,
          field: "month",
          input: input,
          names: MONTH_NAMES
        )
      end
      private_class_method :parse_month_expression

      def self.parse_numeric_expression(str, range, field:, input:, pad:)
        expr = parse_mapped_numeric_expression(str, range, field: field, input: input, names: {})
        return expr if pad <= 0 || expr == "*"

        pad_expression_numbers(expr, pad: pad)
      end
      private_class_method :parse_numeric_expression

      def self.parse_mapped_numeric_expression(str, range, field:, input:, names:)
        raw = str.to_s.strip
        if raw.empty?
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: #{field} is empty"
        end

        parts = raw.split(",").map(&:strip)
        return "*" if parts.any? { |part| part == "*" }

        parts.map do |part|
          mapped_part_to_systemd(part, range, field: field, input: input, names: names)
        end.join(",")
      end
      private_class_method :parse_mapped_numeric_expression

      def self.mapped_part_to_systemd(part, range, field:, input:, names:)
        base, step_str = part.split("/", 2)
        step = if step_str.nil?
                 nil
               else
                 parse_positive_int(step_str, field: field, input: input,
                                              label: "step")
               end

        base_expr =
          if base == "*"
            range.begin.to_s
          elsif (match = /\A(?<start>[^-]+)-(?<finish>[^-]+)\z/.match(base))
            start_value = parse_mapped_value(match[:start], range, field: field, input: input,
                                                                   names: names)
            finish_value = parse_mapped_value(match[:finish], range, field: field, input: input,
                                                                     names: names)
            unless start_value <= finish_value
              raise UnsupportedCronError,
                    "Unsupported cron #{input.inspect}: invalid #{field} range"
            end

            "#{start_value}..#{finish_value}"
          else
            parse_mapped_value(base, range, field: field, input: input, names: names).to_s
          end

        return base_expr if step.nil?

        "#{base_expr}/#{step}"
      end
      private_class_method :mapped_part_to_systemd

      def self.parse_mapped_value(token, range, field:, input:, names:)
        raw = token.to_s.strip
        if raw.empty?
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: empty #{field} token"
        end

        if /\A\d+\z/.match?(raw)
          value = Integer(raw, 10)
          unless range.cover?(value)
            raise UnsupportedCronError, "Unsupported cron #{input.inspect}: #{field} out of range"
          end

          return value
        end

        key = raw.downcase
        if names.key?(key)
          value = names.fetch(key)
          return value if range.cover?(value)
        end

        raise UnsupportedCronError, "Unsupported cron #{input.inspect}: invalid #{field} token"
      end
      private_class_method :parse_mapped_value

      def self.pad_expression_numbers(expr, pad:)
        expr.gsub(%r{(?<![/\d])\d+}) { |m| m.rjust(pad, "0") }
      end
      private_class_method :pad_expression_numbers

      def self.parse_positive_int(str, field:, input:, label:)
        unless /\A\d+\z/.match?(str)
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: #{field} #{label} must be a number"
        end

        value = Integer(str, 10)
        unless value.positive?
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: #{field} #{label} must be positive"
        end

        value
      end
      private_class_method :parse_positive_int

      def self.parse_dow_set(dow_str, input:)
        raw = dow_str.to_s.strip
        if raw.empty?
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: day-of-week is empty"
        end
        return nil if raw == "*"

        present = Array.new(7, false)

        raw.split(",").map(&:strip).each do |part|
          apply_dow_part(present, part, input: input)
        end

        days = present.each_index.select { |idx| present[idx] }
        return nil if days.length == 7

        days
      end
      private_class_method :parse_dow_set

      def self.apply_dow_part(present, part, input:)
        if part.empty?
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: invalid day-of-week token"
        end

        base, step_str = part.split("/", 2)
        step = if step_str.nil?
                 nil
               else
                 parse_positive_int(step_str, field: "day-of-week",
                                              input: input, label: "step")
               end

        sequence =
          if base == "*"
            (0..6).to_a
          elsif (match = /\A(?<start>[^-]+)-(?<finish>[^-]+)\z/.match(base))
            dow_range_sequence(match[:start], match[:finish], input: input)
          else
            start_day = parse_dow_value(base, input: input)
            start_day = 0 if start_day == 7
            step ? (start_day..6).to_a : [start_day]
          end

        if step
          sequence.each_with_index { |day, idx| present[day] = true if (idx % step).zero? }
        else
          sequence.each { |day| present[day] = true }
        end
      end
      private_class_method :apply_dow_part

      def self.dow_range_sequence(start_token, finish_token, input:)
        start_raw = parse_dow_value(start_token, input: input)
        finish_raw = parse_dow_value(finish_token, input: input)

        start_day = start_raw == 7 ? 0 : start_raw
        finish_day = finish_raw == 7 ? 0 : finish_raw

        return (0..6).to_a if start_raw.zero? && finish_raw == 7

        return (start_day..6).to_a + [0] if finish_raw == 7 && !start_raw.zero?

        return (start_day..finish_day).to_a if start_day <= finish_day

        (start_day..6).to_a + (0..finish_day).to_a
      end
      private_class_method :dow_range_sequence

      def self.parse_dow_value(token, input:)
        raw = token.to_s.strip
        if raw.empty?
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: invalid day-of-week token"
        end

        if /\A\d+\z/.match?(raw)
          value = Integer(raw, 10)
          return value if value.between?(0, 7)

          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: day-of-week out of range"
        end

        unless /\A[A-Za-z]+\z/.match?(raw)
          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: invalid day-of-week token"
        end

        key = raw.downcase
        key = key[0, 3] if key.length > 3
        return DOW_NAMES.fetch(key) if DOW_NAMES.key?(key)

        raise UnsupportedCronError, "Unsupported cron #{input.inspect}: invalid day-of-week token"
      end
      private_class_method :parse_dow_value

      def self.format_dow_set(days)
        present = Array.new(7, false)
        days.each { |day| present[day] = true }

        tokens = []
        i = 0
        while i < DOW_ORDER.length
          day = DOW_ORDER.fetch(i)
          unless present.fetch(day)
            i += 1
            next
          end

          start = day
          j = i
          j += 1 while (j + 1) < DOW_ORDER.length && present.fetch(DOW_ORDER.fetch(j + 1))
          finish = DOW_ORDER.fetch(j)

          token =
            if start == finish
              DOW_SYSTEMD.fetch(start)
            else
              "#{DOW_SYSTEMD.fetch(start)}..#{DOW_SYSTEMD.fetch(finish)}"
            end
          tokens << token
          i = j + 1
        end

        tokens.join(",")
      end
      private_class_method :format_dow_set
    end
  end
end
