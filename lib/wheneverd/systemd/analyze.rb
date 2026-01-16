# frozen_string_literal: true

require "open3"

module Wheneverd
  module Systemd
    # Thin wrapper around `systemd-analyze`.
    class Analyze
      DEFAULT_SYSTEMD_ANALYZE = "systemd-analyze"

      # Run `systemd-analyze calendar <value>`.
      #
      # @param value [String] an `OnCalendar=` value
      # @param systemd_analyze [String] path to the `systemd-analyze` executable
      # @return [Array(String, String)] stdout and stderr
      # @raise [Wheneverd::Systemd::SystemdAnalyzeError]
      def self.calendar(value, systemd_analyze: DEFAULT_SYSTEMD_ANALYZE)
        run(systemd_analyze, "calendar", value.to_s)
      end

      # Run `systemd-analyze verify` for unit files.
      #
      # @param paths [Array<String>] unit file paths to verify
      # @param user [Boolean] verify user units with `--user` (default: true)
      # @param systemd_analyze [String] path to the `systemd-analyze` executable
      # @return [Array(String, String)] stdout and stderr
      # @raise [Wheneverd::Systemd::SystemdAnalyzeError]
      def self.verify(paths, user: true, systemd_analyze: DEFAULT_SYSTEMD_ANALYZE)
        run(systemd_analyze, "verify", *Array(paths).map(&:to_s), user: user)
      end

      def self.run(systemd_analyze, *args, user: false)
        cmd = [systemd_analyze.to_s]
        cmd << "--user" if user
        cmd.concat(args.flatten.map(&:to_s))

        stdout, stderr, status = Open3.capture3(*cmd)
        raise SystemdAnalyzeError, format_error(cmd, status, stdout, stderr) unless status.success?

        [stdout, stderr]
      rescue Errno::ENOENT
        raise SystemdAnalyzeError, "systemd-analyze not found (tried: #{systemd_analyze})"
      end

      def self.format_error(cmd, status, stdout, stderr)
        details = []
        details << "command: #{cmd.join(' ')}"
        details << "status: #{status.exitstatus}"
        details << "stdout: #{stdout.strip}" unless stdout.to_s.strip.empty?
        details << "stderr: #{stderr.strip}" unless stderr.to_s.strip.empty?
        "systemd-analyze failed (#{details.join(', ')})"
      end
      private_class_method :format_error
    end
  end
end
