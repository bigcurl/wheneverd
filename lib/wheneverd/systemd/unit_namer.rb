# frozen_string_literal: true

require "digest"

module Wheneverd
  module Systemd
    # Computes stable unit IDs for jobs so units keep names across schedule reordering.
    class UnitNamer
      def self.stable_ids_for(schedule)
        signatures = signatures_for(schedule)
        counts_by_signature = signatures.tally
        occurrences_by_signature = Hash.new(0)

        signatures.map do |sig|
          disambiguate(stable_id_for(sig), sig, counts_by_signature, occurrences_by_signature)
        end
      end

      def self.signatures_for(schedule)
        schedule.entries.flat_map do |entry|
          entry.jobs.map { |job| signature(entry.trigger, job) }
        end
      end
      private_class_method :signatures_for

      def self.disambiguate(stable, signature, counts_by_signature, occurrences_by_signature)
        return stable if counts_by_signature.fetch(signature) == 1

        occurrences_by_signature[signature] += 1
        "#{stable}-#{occurrences_by_signature.fetch(signature)}"
      end
      private_class_method :disambiguate

      def self.signature(trigger, job)
        [trigger_signature(trigger), job_signature(job)].join("\n")
      end
      private_class_method :signature

      def self.trigger_signature(trigger)
        case trigger
        when Wheneverd::Trigger::Interval
          "interval:#{trigger.seconds}"
        when Wheneverd::Trigger::Boot
          "boot:#{trigger.seconds}"
        when Wheneverd::Trigger::Calendar
          "calendar:#{trigger.on_calendar.sort.join('|')}"
        else
          raise ArgumentError, "Unsupported trigger type: #{trigger.class}"
        end
      end
      private_class_method :trigger_signature

      def self.job_signature(job)
        case job
        when Wheneverd::Job::Command
          job.signature
        else
          raise ArgumentError, "Unsupported job type: #{job.class}"
        end
      end
      private_class_method :job_signature

      def self.stable_id_for(signature)
        Digest::SHA256.hexdigest(signature).slice(0, 12)
      end
      private_class_method :stable_id_for
    end
  end
end
