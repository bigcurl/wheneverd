# frozen_string_literal: true

module Wheneverd
  # Implements `wheneverd linger` (manage systemd user lingering via `loginctl`).
  class CLI::Linger < CLI
    option "--user", "NAME", "Username to manage (default: $USER)"

    private

    def username_value
      name = user.to_s.strip
      name = ENV.fetch("USER", "").strip if name.empty?
      raise ArgumentError, "Could not determine username; pass --user NAME" if name.empty?

      name
    end
  end
end

module Wheneverd
  class CLI::Linger::Enable < CLI::Linger
    def execute
      name = username_value
      Wheneverd::Systemd::Loginctl.enable_linger(name)
      puts "Enabled lingering for #{name}"
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end

module Wheneverd
  class CLI::Linger::Disable < CLI::Linger
    def execute
      name = username_value
      Wheneverd::Systemd::Loginctl.disable_linger(name)
      puts "Disabled lingering for #{name}"
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end

module Wheneverd
  class CLI::Linger::Status < CLI::Linger
    def execute
      name = username_value
      stdout, _stderr = Wheneverd::Systemd::Loginctl.show_linger(name)
      puts stdout.strip unless stdout.to_s.strip.empty?
      0
    rescue StandardError => e
      handle_error(e)
    end
  end
end

module Wheneverd
  class CLI::Linger
    self.default_subcommand = "status"

    subcommand "enable", "Enable lingering via loginctl", Wheneverd::CLI::Linger::Enable
    subcommand "disable", "Disable lingering via loginctl", Wheneverd::CLI::Linger::Disable
    subcommand "status", "Show lingering status via loginctl", Wheneverd::CLI::Linger::Status
  end
end
