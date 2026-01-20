# frozen_string_literal: true

module Wheneverd
  module Systemd
    # Builds the text content for systemd unit files.
    #
    # Handles the structure of service and timer unit files, including
    # the marker header, sections, and proper formatting.
    module UnitContentBuilder
      SERVICE_SECTION = ["[Service]", "Type=oneshot"].freeze
      TIMER_SUFFIX = ["Persistent=true", "", "[Install]", "WantedBy=timers.target", ""].freeze

      # Build service unit file contents.
      #
      # @param path_basename [String] unit file name for description
      # @param command [String] ExecStart command
      # @return [String] complete unit file contents
      def self.service_contents(path_basename, command)
        build_unit(
          description: "wheneverd job #{path_basename}",
          sections: SERVICE_SECTION + ["ExecStart=#{command}", ""]
        )
      end

      # Build timer unit file contents.
      #
      # @param path_basename [String] unit file name for description
      # @param timer_lines [Array<String>] timer configuration lines (OnCalendar, OnActiveSec, etc.)
      # @return [String] complete unit file contents
      def self.timer_contents(path_basename, timer_lines)
        build_unit(
          description: "wheneverd timer #{path_basename}",
          sections: ["[Timer]"] + timer_lines + TIMER_SUFFIX
        )
      end

      # Build timer lines for a trigger.
      #
      # @param trigger [Wheneverd::Trigger::Base] the trigger
      # @return [Array<String>] timer configuration lines
      # @raise [ArgumentError] if trigger type is unsupported
      def self.timer_lines_for(trigger)
        # Calendar triggers need special handling to convert DSL specs to systemd specs
        return calendar_timer_lines(trigger) if trigger.is_a?(Wheneverd::Trigger::Calendar)

        unless trigger.respond_to?(:systemd_timer_lines)
          raise ArgumentError, "Unsupported trigger type: #{trigger.class}"
        end

        trigger.systemd_timer_lines
      end

      def self.calendar_timer_lines(trigger)
        trigger.on_calendar.flat_map do |spec|
          CalendarSpec.to_on_calendar_values(spec).map { |value| "OnCalendar=#{value}" }
        end
      end
      private_class_method :calendar_timer_lines

      def self.build_unit(description:, sections:)
        ([
          marker,
          "[Unit]",
          "Description=#{description}",
          ""
        ] + sections).join("\n")
      end
      private_class_method :build_unit

      def self.marker
        "#{Renderer::MARKER_PREFIX} #{Wheneverd::VERSION}; do not edit."
      end
      private_class_method :marker
    end
  end
end
