# frozen_string_literal: true

require_relative "wheneverd/version"

module Wheneverd
  # Top-level namespace for `wheneverd`.
  #
  # This gem loads a Ruby schedule DSL (similar to the `whenever` gem), then renders the result into
  # `systemd` timer + service units. The main entrypoints are:
  #
  # - {Wheneverd::DSL::Loader} for evaluating `config/schedule.rb`
  # - {Wheneverd::Systemd::Renderer} for generating unit contents
  # - {Wheneverd::CLI} for the command-line interface
  class Error < StandardError; end
end

require_relative "wheneverd/errors"
require_relative "wheneverd/duration"
require_relative "wheneverd/interval"
require_relative "wheneverd/core_ext/numeric_duration"
require_relative "wheneverd/job/command"
require_relative "wheneverd/trigger/interval"
require_relative "wheneverd/trigger/calendar"
require_relative "wheneverd/trigger/boot"
require_relative "wheneverd/entry"
require_relative "wheneverd/schedule"
require_relative "wheneverd/dsl/errors"
require_relative "wheneverd/dsl/at_normalizer"
require_relative "wheneverd/dsl/period_parser"
require_relative "wheneverd/dsl/context"
require_relative "wheneverd/dsl/loader"
require_relative "wheneverd/systemd/errors"
require_relative "wheneverd/systemd/time_parser"
require_relative "wheneverd/systemd/cron_parser"
require_relative "wheneverd/systemd/calendar_spec"
require_relative "wheneverd/systemd/unit_namer"
require_relative "wheneverd/systemd/renderer"
require_relative "wheneverd/systemd/analyze"
require_relative "wheneverd/systemd/systemctl"
require_relative "wheneverd/systemd/loginctl"
require_relative "wheneverd/systemd/unit_writer"
require_relative "wheneverd/systemd/unit_deleter"
require_relative "wheneverd/systemd/unit_lister"
