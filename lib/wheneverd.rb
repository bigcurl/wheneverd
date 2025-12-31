# frozen_string_literal: true

require_relative "wheneverd/version"

module Wheneverd
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
