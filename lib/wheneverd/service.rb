# frozen_string_literal: true

module Wheneverd
  # A long-running systemd user service managed alongside scheduled timers.
  class Service
    SAFE_SETTING_NAME = /\A[A-Za-z][A-Za-z0-9]*\z/.freeze

    # @return [String]
    attr_reader :name

    # @return [Wheneverd::Job::Command]
    attr_reader :command

    # @return [String]
    attr_reader :restart

    # @return [String]
    attr_reader :restart_sec

    # @return [Array<String>]
    attr_reader :service_lines

    # @param name [String] stable service name within the schedule
    # @param command [String, Array<String>] command to run as ExecStart
    # @param restart [String] systemd Restart= value
    # @param restart_sec [String] systemd RestartSec= value
    # @param service [Hash, Array<String>] extra [Service] lines
    def initialize(name:, command:, restart: "always", restart_sec: "5s", service: {})
      @name = normalize_name(name)
      @command = Wheneverd::Job::Command.new(command: command)
      @restart = normalize_required_value(restart, "restart")
      @restart_sec = normalize_required_value(restart_sec, "restart_sec")
      @service_lines = normalize_service_lines(service)
    end

    # Stable signature used for unit naming.
    #
    # @return [String]
    def signature
      [
        "service:#{name}",
        command.signature,
        "restart:#{restart}",
        "restart_sec:#{restart_sec}",
        *service_lines
      ].join("\n")
    end

    private

    def normalize_name(value)
      str = value.to_s.strip
      raise InvalidCommandError, "Service name must not be empty" if str.empty?

      str
    end

    def normalize_required_value(value, field)
      str = value.to_s.strip
      raise InvalidCommandError, "Service #{field} must not be empty" if str.empty?

      str
    end

    def normalize_service_lines(value)
      case value
      when Hash
        value.map { |key, setting| normalize_service_setting(key, setting) }
      when Array
        value.map { |line| normalize_service_line(line) }
      else
        raise InvalidCommandError, "Service extra settings must be a Hash or Array"
      end
    end

    def normalize_service_setting(key, value)
      setting_name = key.to_s.strip
      unless SAFE_SETTING_NAME.match?(setting_name)
        raise InvalidCommandError, "Invalid service setting name: #{setting_name.inspect}"
      end

      "#{setting_name}=#{normalize_service_setting_value(value)}"
    end

    def normalize_service_setting_value(value)
      str = value.to_s.strip
      raise InvalidCommandError, "Service setting values must not be empty" if str.empty?
      if str.match?(/[\0\r\n]/)
        raise InvalidCommandError, "Service setting values must not include NUL or newlines"
      end

      str
    end

    def normalize_service_line(line)
      str = line.to_s.strip
      raise InvalidCommandError, "Service lines must not be empty" if str.empty?
      if str.match?(/[\0\r\n]/) || !str.include?("=")
        raise InvalidCommandError, "Service lines must be single KEY=VALUE lines"
      end

      str
    end
  end
end
