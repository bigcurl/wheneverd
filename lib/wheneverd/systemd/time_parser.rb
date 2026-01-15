# frozen_string_literal: true

module Wheneverd
  module Systemd
    # Parses human-friendly times into `HH:MM:SS` for systemd `OnCalendar=` specs.
    module TimeParser
      # @param str [String]
      # @return [String] time in `HH:MM:SS` format
      # @raise [Wheneverd::Systemd::InvalidTimeError]
      def self.parse(str)
        input = str.to_s.strip
        raise InvalidTimeError, "Invalid time: empty" if input.empty?

        if (match = /\A(?<h>\d{1,2}):(?<m>\d{2})(?::(?<s>\d{2}))?\z/.match(input))
          return parse_24h(match)
        end

        if (match = /\A(?<h>\d{1,2})(?::(?<m>\d{2}))?\s*(?<ampm>am|pm)\z/i.match(input))
          return parse_12h(match)
        end

        raise InvalidTimeError, "Invalid time: #{input.inspect}"
      end

      def self.parse_24h(match)
        hour = Integer(match[:h], 10)
        minute = Integer(match[:m], 10)
        second = match[:s] ? Integer(match[:s], 10) : 0

        validate_parts(hour, minute, second)

        format("%<hour>02d:%<minute>02d:%<second>02d", hour: hour, minute: minute, second: second)
      end
      private_class_method :parse_24h

      def self.parse_12h(match)
        hour12 = Integer(match[:h], 10)
        minute = match[:m] ? Integer(match[:m], 10) : 0
        second = 0

        unless hour12.between?(1, 12)
          raise InvalidTimeError, "Invalid time hour: #{hour12} (expected 1..12)"
        end

        validate_parts(0, minute, second)

        hour24 = hour24_from_12h(hour12, match[:ampm].downcase)

        format("%<hour>02d:%<minute>02d:%<second>02d", hour: hour24, minute: minute, second: second)
      end
      private_class_method :parse_12h

      def self.hour24_from_12h(hour12, ampm)
        hour24 = hour12 % 12
        hour24 += 12 if ampm == "pm"
        hour24
      end
      private_class_method :hour24_from_12h

      def self.validate_parts(hour, minute, second)
        validate_part("hour", hour, 0..23)
        validate_part("minute", minute, 0..59)
        validate_part("second", second, 0..59)
      end
      private_class_method :validate_parts

      def self.validate_part(name, value, range)
        return if range.cover?(value)

        raise InvalidTimeError, "Invalid time #{name}: #{value} (expected #{range})"
      end
      private_class_method :validate_part
    end
  end
end
