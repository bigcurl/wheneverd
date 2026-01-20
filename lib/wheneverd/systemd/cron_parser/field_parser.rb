# frozen_string_literal: true

module Wheneverd
  module Systemd
    module CronParser
      # Parses individual cron field expressions (minute, hour, day-of-month, month).
      #
      # Handles:
      # - Wildcards: `*`
      # - Lists: `1,2,3`
      # - Ranges: `1-5`
      # - Steps: `*/2`, `1-10/2`
      # - Named values (for month): `jan`, `feb`, etc.
      module FieldParser
        # Parses a numeric cron field expression.
        #
        # @param str [String] the field value
        # @param range [Range] valid range for values
        # @param field [String] field name for error messages
        # @param input [String] full cron expression for error messages
        # @param pad [Integer] zero-padding width (0 = no padding)
        # @return [String] systemd-compatible expression
        # @raise [Wheneverd::Systemd::UnsupportedCronError]
        def self.parse_numeric(str, range, field:, input:, pad:)
          expr = parse_mapped(str, range, field: field, input: input, names: {})
          return expr if pad <= 0 || expr == "*"

          pad_expression_numbers(expr, pad: pad)
        end

        # Parses a cron field expression with optional name mappings.
        #
        # @param str [String] the field value
        # @param range [Range] valid range for values
        # @param field [String] field name for error messages
        # @param input [String] full cron expression for error messages
        # @param names [Hash<String, Integer>] name-to-value mappings (e.g., {"jan" => 1})
        # @return [String] systemd-compatible expression
        # @raise [Wheneverd::Systemd::UnsupportedCronError]
        def self.parse_mapped(str, range, field:, input:, names:)
          raw = str.to_s.strip
          raise_empty_field_error(field, input) if raw.empty?

          parts = raw.split(",").map(&:strip)
          return "*" if parts.any? { |part| part == "*" }

          parts.map do |part|
            part_to_systemd(part, range, field: field, input: input, names: names)
          end.join(",")
        end

        def self.part_to_systemd(part, range, field:, input:, names:)
          base, step_str = part.split("/", 2)
          step = parse_step(step_str, field: field, input: input)

          base_expr = parse_base_expression(base, range, field: field, input: input, names: names)

          return base_expr if step.nil?

          "#{base_expr}/#{step}"
        end
        private_class_method :part_to_systemd

        def self.parse_base_expression(base, range, field:, input:, names:)
          if base == "*"
            range.begin.to_s
          elsif (match = /\A(?<start>[^-]+)-(?<finish>[^-]+)\z/.match(base))
            parse_range_expression(match[:start], match[:finish], range, field: field, input: input,
                                                                         names: names)
          else
            parse_value(base, range, field: field, input: input, names: names).to_s
          end
        end
        private_class_method :parse_base_expression

        def self.parse_range_expression(start_token, finish_token, range, field:, input:, names:)
          start_value = parse_value(start_token, range, field: field, input: input, names: names)
          finish_value = parse_value(finish_token, range, field: field, input: input, names: names)

          unless start_value <= finish_value
            raise UnsupportedCronError,
                  "Unsupported cron #{input.inspect}: invalid #{field} range"
          end

          "#{start_value}..#{finish_value}"
        end
        private_class_method :parse_range_expression

        def self.parse_value(token, range, field:, input:, names:)
          raw = token.to_s.strip
          raise_empty_token_error(field, input) if raw.empty?

          return parse_numeric_value(raw, range, field: field, input: input) if /\A\d+\z/.match?(raw)

          parse_named_value(raw, range, field: field, input: input, names: names)
        end
        private_class_method :parse_value

        def self.parse_numeric_value(raw, range, field:, input:)
          value = Integer(raw, 10)
          return value if range.cover?(value)

          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: #{field} out of range"
        end
        private_class_method :parse_numeric_value

        def self.parse_named_value(raw, range, field:, input:, names:)
          key = raw.downcase
          if names.key?(key)
            value = names.fetch(key)
            return value if range.cover?(value)
          end

          raise UnsupportedCronError, "Unsupported cron #{input.inspect}: invalid #{field} token"
        end
        private_class_method :parse_named_value

        def self.parse_step(step_str, field:, input:)
          return nil if step_str.nil?

          parse_positive_int(step_str, field: field, input: input, label: "step")
        end
        private_class_method :parse_step

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

        def self.pad_expression_numbers(expr, pad:)
          expr.gsub(%r{(?<![/\d])\d+}) { |m| m.rjust(pad, "0") }
        end
        private_class_method :pad_expression_numbers

        def self.raise_empty_field_error(field, input)
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: #{field} is empty"
        end
        private_class_method :raise_empty_field_error

        def self.raise_empty_token_error(field, input)
          raise UnsupportedCronError,
                "Unsupported cron #{input.inspect}: empty #{field} token"
        end
        private_class_method :raise_empty_token_error
      end
    end
  end
end
