# frozen_string_literal: true

require "fileutils"
require "tempfile"

module Wheneverd
  module Systemd
    # Writes rendered systemd units to a target directory (defaulting to the user unit dir).
    class UnitWriter
      DEFAULT_UNIT_DIR = File.join(Dir.home, ".config", "systemd", "user").freeze

      # @param units [Array<Wheneverd::Systemd::Unit>]
      # @param identifier [String, nil] required when pruning
      # @param unit_dir [String]
      # @param dry_run [Boolean] return paths without writing
      # @param prune [Boolean] delete previously generated units for `identifier` not in `units`
      # @return [Array<String>] destination paths
      def self.write(units, unit_dir: DEFAULT_UNIT_DIR, dry_run: false, prune: false,
                     identifier: nil)
        validate_units!(units)
        dest_dir = File.expand_path(unit_dir.to_s)
        paths = destination_paths(units, dest_dir)
        return paths if dry_run

        write_units(units, paths, dest_dir, prune: prune, identifier: identifier)
        paths
      end

      def self.validate_units!(units)
        raise ArgumentError, "units must be an Array" unless units.is_a?(Array)
      end
      private_class_method :validate_units!

      def self.destination_paths(units, dest_dir)
        units.map { |unit| File.join(dest_dir, unit.path_basename) }
      end
      private_class_method :destination_paths

      def self.write_units(units, paths, dest_dir, prune:, identifier:)
        FileUtils.mkdir_p(dest_dir)
        if prune
          prune_stale_units(
            dest_dir,
            identifier: identifier,
            keep_basenames: units.map(&:path_basename)
          )
        end
        write_unit_files(units, paths, dest_dir)
      end
      private_class_method :write_units

      def self.write_unit_files(units, paths, dest_dir)
        units.each_with_index do |unit, idx|
          atomic_write(paths.fetch(idx), unit.contents.to_s, dir: dest_dir)
        end
      end
      private_class_method :write_unit_files

      def self.prune_stale_units(dest_dir, identifier:, keep_basenames:)
        raise ArgumentError, "identifier is required when prune is true" if identifier.nil?

        keep = keep_basenames.to_h { |basename| [basename, true] }
        stale_unit_paths(dest_dir, identifier: identifier, keep: keep).each do |path|
          FileUtils.rm_f(path)
        end
      end
      private_class_method :prune_stale_units

      def self.stale_unit_paths(dest_dir, identifier:, keep:)
        pattern = UnitPathUtils.basename_pattern(identifier)
        Dir.children(dest_dir).filter_map do |basename|
          next if keep.key?(basename)

          path = File.join(dest_dir, basename)
          next unless stale_unit_path?(basename, path, pattern)

          path
        end
      end
      private_class_method :stale_unit_paths

      def self.stale_unit_path?(basename, path, pattern)
        return false unless pattern.match?(basename)
        return false unless File.file?(path)

        UnitPathUtils.generated_marker?(path)
      end
      private_class_method :stale_unit_path?

      def self.atomic_write(dest_path, contents, dir:)
        basename = File.basename(dest_path)
        tmp = Tempfile.new([".#{basename}.", ".tmp"], dir)
        tmp.write(contents)
        tmp.flush
        tmp.fsync
        tmp.close

        File.rename(tmp.path, dest_path)
      ensure
        tmp&.close
        tmp&.unlink
      end
      private_class_method :atomic_write
    end
  end
end
