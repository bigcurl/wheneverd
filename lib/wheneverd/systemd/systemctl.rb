# frozen_string_literal: true

require "open3"

module Wheneverd
  module Systemd
    class Systemctl
      def self.run(*args, user: true)
        cmd = ["systemctl"]
        cmd << "--user" if user
        cmd << "--no-pager"
        cmd.concat(args.flatten.map(&:to_s))

        stdout, stderr, status = Open3.capture3(*cmd)
        raise SystemctlError, format_error(cmd, status, stdout, stderr) unless status.success?

        [stdout, stderr]
      end

      def self.format_error(cmd, status, stdout, stderr)
        details = []
        details << "command: #{cmd.join(' ')}"
        details << "status: #{status.exitstatus}"
        details << "stdout: #{stdout.strip}" unless stdout.to_s.strip.empty?
        details << "stderr: #{stderr.strip}" unless stderr.to_s.strip.empty?
        "systemctl failed (#{details.join(', ')})"
      end
      private_class_method :format_error
    end
  end
end
