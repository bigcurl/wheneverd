# frozen_string_literal: true

module Wheneverd
  module Systemd
    # Lists previously generated unit file paths for a given identifier.
    class UnitLister
      DEFAULT_UNIT_DIR = UnitWriter::DEFAULT_UNIT_DIR

      # @param identifier [String]
      # @param unit_dir [String]
      # @return [Array<String>] unit file paths
      def self.list(identifier:, unit_dir: DEFAULT_UNIT_DIR)
        dest_dir = File.expand_path(unit_dir.to_s)
        return [] unless Dir.exist?(dest_dir)

        unit_paths(dest_dir, UnitPathUtils.basename_pattern(identifier))
      end

      def self.unit_paths(dest_dir, pattern)
        Dir.children(dest_dir).sort.filter_map do |basename|
          next unless pattern.match?(basename)

          path = File.join(dest_dir, basename)
          next unless File.file?(path)
          next unless UnitPathUtils.generated_marker?(path)

          path
        end
      end
      private_class_method :unit_paths
    end
  end
end
