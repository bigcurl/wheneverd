# frozen_string_literal: true

module Wheneverd
  class Entry
    attr_reader :trigger, :jobs, :roles

    def initialize(trigger:, jobs: [], roles: nil)
      raise ArgumentError, "trigger is required" if trigger.nil?

      @trigger = trigger
      @jobs = jobs.dup
      @roles = roles
    end

    def add_job(job)
      jobs << job
      self
    end
  end
end
