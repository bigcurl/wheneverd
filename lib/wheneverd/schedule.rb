# frozen_string_literal: true

module Wheneverd
  # A schedule is an ordered list of {Entry} objects.
  #
  # Schedules are typically created by evaluating a schedule file in the DSL context.
  class Schedule
    # @return [Array<Entry>]
    attr_reader :entries

    # @return [Array<Wheneverd::Service>]
    attr_reader :services

    # @param entries [Array<Entry>]
    # @param services [Array<Wheneverd::Service>]
    def initialize(entries: [], services: [])
      @entries = entries.dup
      @services = services.dup
    end

    # Append an entry to the schedule.
    #
    # @param entry [Entry]
    # @return [Schedule] self
    def add_entry(entry)
      entries << entry
      self
    end

    # Append a long-running service to the schedule.
    #
    # @param service [Wheneverd::Service]
    # @return [Schedule] self
    def add_service(service)
      services << service
      self
    end
  end
end
