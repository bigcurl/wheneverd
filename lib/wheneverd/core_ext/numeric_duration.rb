# frozen_string_literal: true

module Wheneverd
  module CoreExt
    # `Numeric` helpers for creating {Wheneverd::Duration} values.
    #
    # @example
    #   every 5.minutes do
    #     command "echo hello"
    #   end
    module NumericDuration
      def second
        Wheneverd::Duration.new(to_duration_seconds(1))
      end
      alias seconds second

      def minute
        Wheneverd::Duration.new(to_duration_seconds(60))
      end
      alias minutes minute

      def hour
        Wheneverd::Duration.new(to_duration_seconds(60 * 60))
      end
      alias hours hour

      def day
        Wheneverd::Duration.new(to_duration_seconds(60 * 60 * 24))
      end
      alias days day

      def week
        Wheneverd::Duration.new(to_duration_seconds(60 * 60 * 24 * 7))
      end
      alias weeks week

      private

      def to_duration_seconds(multiplier)
        unless is_a?(Integer)
          raise ArgumentError, "Duration helpers require an Integer receiver (got #{self.class})"
        end

        self * multiplier
      end
    end
  end
end

# Extend Ruby's `Numeric` with duration helpers.
#
# @!parse
#   class ::Numeric
#     include Wheneverd::CoreExt::NumericDuration
#   end
Numeric.include(Wheneverd::CoreExt::NumericDuration)
