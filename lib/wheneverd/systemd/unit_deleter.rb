# frozen_string_literal: true

require "fileutils"

module Wheneverd
  module Systemd
    class UnitDeleter
      DEFAULT_UNIT_DIR = UnitWriter::DEFAULT_UNIT_DIR

      def self.delete(identifier:, unit_dir: DEFAULT_UNIT_DIR, dry_run: false)
        dest_dir = File.expand_path(unit_dir.to_s)
        return [] unless Dir.exist?(dest_dir)

        deleted = deletable_paths(dest_dir, basename_pattern(identifier))
        deleted.each { |path| FileUtils.rm_f(path) unless dry_run }
        deleted
      end

      def self.deletable_paths(dest_dir, pattern)
        Dir.children(dest_dir).sort.filter_map do |basename|
          next unless pattern.match?(basename)

          path = File.join(dest_dir, basename)
          next unless File.file?(path)
          next unless generated_marker?(path)

          path
        end
      end
      private_class_method :deletable_paths

      def self.basename_pattern(identifier)
        id = sanitize_identifier(identifier)
        /\Awheneverd-#{Regexp.escape(id)}-e\d+-j\d+\.(service|timer)\z/
      end
      private_class_method :basename_pattern

      def self.generated_marker?(path)
        first_line = File.open(path, "r") { |f| f.gets.to_s }
        first_line.start_with?(Wheneverd::Systemd::Renderer::MARKER_PREFIX)
      end
      private_class_method :generated_marker?

      def self.sanitize_identifier(identifier)
        raw = identifier.to_s.strip
        raise InvalidIdentifierError, "identifier must not be empty" if raw.empty?

        sanitized = raw.gsub(/[^A-Za-z0-9_-]/, "-").gsub(/-+/, "-").gsub(/\A-|-+\z/, "")
        if sanitized.empty?
          raise InvalidIdentifierError,
                "identifier must include at least one alphanumeric character"
        end

        sanitized
      end
      private_class_method :sanitize_identifier
    end
  end
end
