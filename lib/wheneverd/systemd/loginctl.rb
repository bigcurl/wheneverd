# frozen_string_literal: true

require "open3"

module Wheneverd
  module Systemd
    # Thin wrapper around `loginctl` that raises on non-zero exit status.
    class Loginctl
      # Run `loginctl` and return stdout/stderr.
      #
      # @param args [Array<String>]
      # @return [Array(String, String)] stdout and stderr
      # @raise [Wheneverd::Systemd::LoginctlError]
      def self.run(*args)
        cmd = ["loginctl", "--no-pager"]
        cmd.concat(args.flatten.map(&:to_s))

        stdout, stderr, status = Open3.capture3(*cmd)
        raise LoginctlError, format_error(cmd, status, stdout, stderr) unless status.success?

        [stdout, stderr]
      end

      # Enable lingering for a user (so their `systemctl --user` instance can run while logged out).
      #
      # @param username [String]
      # @return [Array(String, String)] stdout and stderr
      def self.enable_linger(username)
        run("enable-linger", username)
      end

      # Disable lingering for a user.
      #
      # @param username [String]
      # @return [Array(String, String)] stdout and stderr
      def self.disable_linger(username)
        run("disable-linger", username)
      end

      # Show lingering state for a user (includes a `Linger=` line).
      #
      # @param username [String]
      # @return [Array(String, String)] stdout and stderr
      def self.show_linger(username)
        run("show-user", username, "-p", "Linger")
      end

      def self.format_error(cmd, status, stdout, stderr)
        details = []
        details << "command: #{cmd.join(' ')}"
        details << "status: #{status.exitstatus}"
        details << "stdout: #{stdout.strip}" unless stdout.to_s.strip.empty?
        details << "stderr: #{stderr.strip}" unless stderr.to_s.strip.empty?
        "loginctl failed (#{details.join(', ')})"
      end
      private_class_method :format_error
    end
  end
end
