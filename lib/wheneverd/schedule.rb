# frozen_string_literal: true

module Wheneverd
  # A schedule is an ordered list of {Entry} objects.
  #
  # Schedules are typically created by evaluating a schedule file in the DSL context.
  class Schedule
    # @return [Array<Entry>]
    attr_reader :entries

    # @param entries [Array<Entry>]
    def initialize(entries: [])
      @entries = entries.dup
    end

    # Append an entry to the schedule.
    #
    # @param entry [Entry]
    # @return [Schedule] self
    def add_entry(entry)
      entries << entry
      self
    end
  end
end
