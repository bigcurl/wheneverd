# frozen_string_literal: true

module Wheneverd
  module DSL
    class Error < Wheneverd::Error
      attr_reader :path

      def initialize(message, path:)
        super(message)
        @path = path
      end
    end

    class LoadError < Error; end
    class InvalidPeriodError < Error; end
    class InvalidAtError < Error; end
  end
end
