# frozen_string_literal: true

module Wheneverd
  module Systemd
    module CronParser
      # Parses and formats day-of-week cron field expressions.
      #
      # Day-of-week has specialized handling:
      # - Both 0 and 7 represent Sunday
      # - Wrap-around ranges (e.g., Fri-Mon)
      # - Formatting to systemd's Mon..Fri syntax
      module DowParser
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

        # Day order for formatting (Mon-Sun instead of Sun-Sat)
        DOW_ORDER = [1, 2, 3, 4, 5, 6, 0].freeze

        # Parses a day-of-week field into a set of days.
        #
        # @param dow_str [String] the day-of-week field value
        # @param input [String] full cron expression for error messages
        # @return [Array<Integer>, nil] array of day numbers (0-6), or nil if all days
        # @raise [Wheneverd::Systemd::UnsupportedCronError]
        def self.parse(dow_str, input:)
          raw = dow_str.to_s.strip
          raise_empty_error(input) if raw.empty?
          return nil if raw == "*"

          present = Array.new(7, false)

          raw.split(",").map(&:strip).each do |part|
            apply_part(present, part, input: input)
          end

          days = present.each_index.select { |idx| present[idx] }
          return nil if days.length == 7

          days
        end

        # Formats a set of days into a systemd-compatible expression.
        #
        # @param days [Array<Integer>] array of day numbers (0-6)
        # @return [String] systemd expression (e.g., "Mon..Fri", "Mon,Wed,Fri")
        def self.format(days)
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

            token = format_range(start, finish)
            tokens << token
            i = j + 1
          end

          tokens.join(",")
        end

        def self.apply_part(present, part, input:)
          raise_invalid_token_error(input) if part.empty?

          base, step_str = part.split("/", 2)
          step = parse_step(step_str, input: input)

          sequence = parse_sequence(base, step, input: input)

          if step
            sequence.each_with_index { |day, idx| present[day] = true if (idx % step).zero? }
          else
            sequence.each { |day| present[day] = true }
          end
        end
        private_class_method :apply_part

        def self.parse_sequence(base, step, input:)
          if base == "*"
            (0..6).to_a
          elsif (match = /\A(?<start>[^-]+)-(?<finish>[^-]+)\z/.match(base))
            range_sequence(match[:start], match[:finish], input: input)
          else
            start_day = parse_value(base, input: input)
            start_day = 0 if start_day == 7
            step ? (start_day..6).to_a : [start_day]
          end
        end
        private_class_method :parse_sequence

        def self.range_sequence(start_token, finish_token, input:)
          start_raw = parse_value(start_token, input: input)
          finish_raw = parse_value(finish_token, input: input)

          start_day = start_raw == 7 ? 0 : start_raw
          finish_day = finish_raw == 7 ? 0 : finish_raw

          return (0..6).to_a if start_raw.zero? && finish_raw == 7

          return (start_day..6).to_a + [0] if finish_raw == 7 && !start_raw.zero?

          return (start_day..finish_day).to_a if start_day <= finish_day

          (start_day..6).to_a + (0..finish_day).to_a
        end
        private_class_method :range_sequence

        def self.parse_value(token, input:)
          raw = token.to_s.strip
          raise_invalid_token_error(input) if raw.empty?

          return parse_numeric_value(raw, input: input) if /\A\d+\z/.match?(raw)

          parse_named_value(raw, input: input)
        end
        private_class_method :parse_value

        def self.parse_numeric_value(raw, input:)
          value = Integer(raw, 10)
          return value if value.between?(0, 7)

          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: day-of-week out of range"
        end
        private_class_method :parse_numeric_value

        def self.parse_named_value(raw, input:)
          unless /\A[A-Za-z]+\z/.match?(raw)
            raise UnsupportedCronError,
                  "Unsupported cron #{input.inspect}: invalid day-of-week token"
          end

          key = raw.downcase
          key = key[0, 3] if key.length > 3
          return DOW_NAMES.fetch(key) if DOW_NAMES.key?(key)

          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: invalid day-of-week token"
        end
        private_class_method :parse_named_value

        def self.parse_step(step_str, input:)
          return nil if step_str.nil?

          unless /\A\d+\z/.match?(step_str)
            raise UnsupportedCronError,
                  "Unsupported cron #{input.inspect}: day-of-week step must be a number"
          end

          value = Integer(step_str, 10)
          unless value.positive?
            raise UnsupportedCronError,
                  "Unsupported cron #{input.inspect}: day-of-week step must be positive"
          end

          value
        end
        private_class_method :parse_step

        def self.format_range(start, finish)
          if start == finish
            DOW_SYSTEMD.fetch(start)
          else
            "#{DOW_SYSTEMD.fetch(start)}..#{DOW_SYSTEMD.fetch(finish)}"
          end
        end
        private_class_method :format_range

        def self.raise_empty_error(input)
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: day-of-week is empty"
        end
        private_class_method :raise_empty_error

        def self.raise_invalid_token_error(input)
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: invalid day-of-week token"
        end
        private_class_method :raise_invalid_token_error
      end
    end
  end
end
