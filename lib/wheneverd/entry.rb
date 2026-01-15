# frozen_string_literal: true

module Wheneverd
  # A single scheduled unit of work.
  #
  # An entry ties together a trigger (when to run) and one or more jobs (what to run).
  class Entry
    # @return [Wheneverd::Trigger::Interval, Wheneverd::Trigger::Calendar, Wheneverd::Trigger::Boot]
    attr_reader :trigger, :jobs, :roles

    # @param trigger [Object] a trigger object describing when to run
    # @param jobs [Array<Object>] job objects (usually {Wheneverd::Job::Command})
    # @param roles [Object] stored but currently not used for filtering
    def initialize(trigger:, jobs: [], roles: nil)
      raise ArgumentError, "trigger is required" if trigger.nil?

      @trigger = trigger
      @jobs = jobs.dup
      @roles = roles
    end

    # Append a job to the entry.
    #
    # @param job [Object]
    # @return [Entry] self
    def add_job(job)
      jobs << job
      self
    end
  end
end
