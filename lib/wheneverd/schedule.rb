# frozen_string_literal: true

module Wheneverd
  class Schedule
    attr_reader :entries

    def initialize(entries: [])
      @entries = entries.dup
    end

    def add_entry(entry)
      entries << entry
      self
    end
  end
end
