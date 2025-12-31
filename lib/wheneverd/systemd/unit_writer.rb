# frozen_string_literal: true

require "fileutils"
require "tempfile"

module Wheneverd
  module Systemd
    class UnitWriter
      DEFAULT_UNIT_DIR = File.join(Dir.home, ".config", "systemd", "user").freeze

      def self.write(units, unit_dir: DEFAULT_UNIT_DIR, dry_run: false)
        raise ArgumentError, "units must be an Array" unless units.is_a?(Array)

        dest_dir = File.expand_path(unit_dir.to_s)
        paths = units.map { |unit| File.join(dest_dir, unit.path_basename) }

        return paths if dry_run

        FileUtils.mkdir_p(dest_dir)

        units.each_with_index do |unit, idx|
          atomic_write(paths.fetch(idx), unit.contents.to_s, dir: dest_dir)
        end

        paths
      end

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
