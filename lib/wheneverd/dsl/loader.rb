# frozen_string_literal: true

module Wheneverd
  module DSL
    class Loader
      def self.load_file(path)
        absolute_path = File.expand_path(path.to_s)
        evaluate_file(absolute_path)
      rescue Wheneverd::DSL::Error => e
        raise_with_path(e, absolute_path)
      rescue Wheneverd::Error, StandardError => e
        raise_load_error(e, absolute_path)
      end

      def self.evaluate_file(absolute_path)
        context = Wheneverd::DSL::Context.new(path: absolute_path)
        source = File.read(absolute_path)

        context.instance_eval(source, absolute_path, 1)
        context.schedule
      end
      private_class_method :evaluate_file

      def self.raise_with_path(error, absolute_path)
        wrapped = error.class.new("#{absolute_path}: #{error.message}", path: absolute_path)
        wrapped.set_backtrace(error.backtrace)
        raise wrapped
      end
      private_class_method :raise_with_path

      def self.raise_load_error(error, absolute_path)
        wrapped = LoadError.new("#{absolute_path}: #{error.message}", path: absolute_path)
        wrapped.set_backtrace(error.backtrace)
        raise wrapped
      end
      private_class_method :raise_load_error
    end
  end
end
