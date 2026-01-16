# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd diff` (rendered output vs files on disk).
  #
  # Exit statuses follow `diff` semantics:
  # - 0: no differences
  # - 1: differences found
  # - 2: error
  class CLI::Diff < CLI
    def execute
      diffs = unit_diffs
      return 0 if diffs.empty?

      diffs.each_with_index do |diff, idx|
        puts "" if idx.positive?
        puts diff
      end
      1
    rescue StandardError => e
      handle_error(e)
      2
    end

    private

    def unit_diffs
      rendered = rendered_units_by_basename
      installed = installed_units_by_basename

      diffs = rendered.map do |basename, contents|
        diff_for_rendered_unit(basename, contents, installed[basename])
      end
      diffs.concat(stale_unit_diffs(rendered: rendered, installed: installed))
      diffs.compact
    end

    def stale_unit_diffs(rendered:, installed:)
      (installed.keys - rendered.keys).sort.map do |basename|
        diff_for_removed_unit(basename, installed.fetch(basename))
      end
    end

    def rendered_units_by_basename
      render_units.to_h { |unit| [unit.path_basename, unit.contents.to_s] }
    end

    def installed_units_by_basename
      paths = Wheneverd::Systemd::UnitLister.list(identifier: identifier_value, unit_dir: unit_dir)
      paths.to_h { |path| [File.basename(path), path] }
    end

    def diff_for_rendered_unit(basename, rendered_contents, installed_path)
      return diff_for_added_unit(basename, rendered_contents) if installed_path.nil?

      installed_contents = File.read(installed_path)
      return nil if installed_contents == rendered_contents

      diff_for_changed_unit(basename, installed_path, installed_contents, rendered_contents)
    end

    def diff_for_added_unit(basename, rendered_contents)
      dest_path = File.join(File.expand_path(unit_dir.to_s), basename)
      header = ["diff --wheneverd #{basename}", "--- /dev/null", "+++ #{dest_path}"]
      (header + line_diff("", rendered_contents)).join("\n")
    end

    def diff_for_removed_unit(basename, installed_path)
      header = ["diff --wheneverd #{basename}", "--- #{installed_path}", "+++ /dev/null"]
      (header + line_diff(File.read(installed_path), "")).join("\n")
    end

    def diff_for_changed_unit(basename, installed_path, installed_contents, rendered_contents)
      header = ["diff --wheneverd #{basename}", "--- #{installed_path}",
                "+++ #{basename} (rendered)"]
      (header + line_diff(installed_contents, rendered_contents)).join("\n")
    end

    def line_diff(old_contents, new_contents)
      old_lines = old_contents.to_s.lines.map(&:chomp)
      new_lines = new_contents.to_s.lines.map(&:chomp)
      max = [old_lines.length, new_lines.length].max

      (0...max).flat_map do |idx|
        diff_lines_for(old_lines[idx], new_lines[idx])
      end
    end

    def diff_lines_for(old_line, new_line)
      return [] if old_line.nil? && new_line.nil?
      return [" #{old_line}"] if old_line == new_line
      return ["-#{old_line}", "+#{new_line}"] if old_line && new_line
      return ["-#{old_line}"] if old_line

      ["+#{new_line}"]
    end
  end
end
