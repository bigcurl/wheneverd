# frozen_string_literal: true

require "json"
require "open3"
require "rake/testtask"

Rake::TestTask.new do |t|
  t.libs << "lib"
  t.pattern = "test/**/*_test.rb"
end

task default: :ci

def rubocop_corrected_count(output)
  output.scan(/(\d+)\s+offenses?\s+corrected\b/i).flatten.sum(&:to_i)
end

def run_and_echo(command)
  output, status = Open3.capture2e(command)
  $stdout.print(output)
  [output, status]
end

def announce(message)
  puts("\n==> #{message}")
end

CI_STATE = {
  rubocop: { ran: false, reran: false, corrected: 0, success: nil },
  test: { ran: false, success: nil },
  coverage: { line: nil, minimum: nil }
}.freeze

def record_ci(section, key, value)
  CI_STATE.fetch(section)[key] = value
end

def ci_status_label(value)
  case value
  when true
    "OK"
  when false
    "FAILED"
  else
    "SKIPPED"
  end
end

def read_line_coverage
  coverage_path = File.expand_path("coverage/.last_run.json", __dir__)
  return nil unless File.exist?(coverage_path)

  JSON.parse(File.read(coverage_path)).dig("result", "line")
rescue JSON::ParserError
  nil
end

def print_ci_rubocop_summary
  rubocop = CI_STATE.fetch(:rubocop)
  details = []
  details << "corrected #{rubocop[:corrected]}" if rubocop[:ran]
  details << "reran" if rubocop[:reran]
  suffix = details.any? ? " (#{details.join(', ')})" : ""
  puts("RuboCop: #{ci_status_label(rubocop[:success])}#{suffix}")
end

def print_ci_test_summary
  test = CI_STATE.fetch(:test)
  puts("Tests: #{ci_status_label(test[:success])}")
end

def print_ci_coverage_summary
  coverage = CI_STATE.fetch(:coverage)
  line = coverage[:line]
  min = coverage[:minimum]

  unless line
    puts("Coverage: (no data)")
    return
  end

  min_label = min ? format(" (min %<min>d%%)", min: min) : ""
  puts(format("Coverage: %<line>.1f%%%<min_label>s", line: line, min_label: min_label))
end

def print_ci_summary
  announce("Summary")
  print_ci_rubocop_summary
  print_ci_test_summary
  print_ci_coverage_summary
end

def init_rubocop_state
  record_ci(:rubocop, :ran, true)
  record_ci(:rubocop, :reran, false)
end

def run_rubocop_pass(command, label)
  announce(label)
  run_and_echo(command)
end

def record_rubocop_corrections(output)
  corrected = rubocop_corrected_count(output)
  record_ci(:rubocop, :corrected, corrected)
  corrected
end

def rerun_rubocop_if_corrected(command, corrected)
  return nil unless corrected.positive?

  announce("Re-running RuboCop (-A) after corrections")
  record_ci(:rubocop, :reran, true)
  _output, status = run_and_echo(command)
  status
end

def finalize_rubocop(status)
  record_ci(:rubocop, :success, status.success?)
  abort("RuboCop failed") unless status.success?
end

def run_ci_rubocop
  command = "bundle exec rubocop -A ."
  init_rubocop_state
  output, status = run_rubocop_pass(command, "Running RuboCop (-A)")
  corrected = record_rubocop_corrections(output)
  status = rerun_rubocop_if_corrected(command, corrected) || status
  finalize_rubocop(status)
rescue Errno::ENOENT => e
  abort(e.message)
end

def run_ci_tests
  announce("Running tests (Minitest + SimpleCov)")

  record_ci(:test, :ran, true)
  record_ci(:coverage, :minimum, ENV.fetch("MINIMUM_COVERAGE", "100").to_i)

  Rake::Task["test"].invoke
  record_ci(:test, :success, true)
rescue SystemExit, StandardError
  record_ci(:test, :success, false)
  raise
ensure
  record_ci(:coverage, :line, read_line_coverage)
end

namespace :ci do
  desc "Run RuboCop with autocorrect (-A) (twice if corrections were made)"
  task :rubocop do
    run_ci_rubocop
  end

  desc "Run tests (with coverage)"
  task :test do
    run_ci_tests
  end

  desc "Print a summary of the last CI run"
  task :summary do
    record_ci(:coverage, :minimum, ENV.fetch("MINIMUM_COVERAGE", "100").to_i)
    record_ci(:coverage, :line, read_line_coverage)
    print_ci_summary
  end
end

desc "Run RuboCop and tests (with coverage)"
task :ci do
  Rake::Task["ci:rubocop"].invoke
  Rake::Task["ci:test"].invoke
ensure
  print_ci_summary
end
