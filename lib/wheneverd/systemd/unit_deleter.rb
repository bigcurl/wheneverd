# frozen_string_literal: true

require "fileutils"

module Wheneverd
  module Systemd
    # Deletes previously generated unit files for a given identifier.
    class UnitDeleter
      DEFAULT_UNIT_DIR = UnitWriter::DEFAULT_UNIT_DIR

      # @param identifier [String]
      # @param unit_dir [String]
      # @param dry_run [Boolean] return paths without deleting
      # @return [Array<String>] deleted paths
      def self.delete(identifier:, unit_dir: DEFAULT_UNIT_DIR, dry_run: false)
        dest_dir = File.expand_path(unit_dir.to_s)
        return [] unless Dir.exist?(dest_dir)

        deleted = deletable_paths(dest_dir, UnitPathUtils.basename_pattern(identifier))
        deleted.each { |path| FileUtils.rm_f(path) unless dry_run }
        deleted
      end

      def self.deletable_paths(dest_dir, pattern)
        Dir.children(dest_dir).sort.filter_map do |basename|
          next unless pattern.match?(basename)

          path = File.join(dest_dir, basename)
          next unless File.file?(path)
          next unless UnitPathUtils.generated_marker?(path)

          path
        end
      end
      private_class_method :deletable_paths
    end
  end
end
