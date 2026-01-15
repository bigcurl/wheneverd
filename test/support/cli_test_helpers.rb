# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "wheneverd/cli"

module CLITestHelpers
  SYSTEMCTL_USER_PREFIX = ["systemctl", "--user", "--no-pager"].freeze

  def run_cli(args)
    status = nil
    out, err = capture_io { status = Wheneverd::CLI.run("wheneverd", args) }
    [status, out, err]
  end

  def run_activate_with_capture3_stub(identifier: "demo", **kwargs)
    run_cli_with_capture3_stub(["activate", "--identifier", identifier], **kwargs)
  end

  def run_deactivate_with_capture3_stub(identifier: "demo", **kwargs)
    run_cli_with_capture3_stub(["deactivate", "--identifier", identifier], **kwargs)
  end

  def run_reload_with_capture3_stub(unit_dir:, identifier: "demo", **kwargs)
    run_cli_with_capture3_stub(
      ["reload", "--identifier", identifier, "--unit-dir", unit_dir],
      **kwargs
    )
  end

  def write_empty_schedule(path = File.join("config", "schedule.rb"))
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "# frozen_string_literal: true\n")
  end

  def with_capture3_stub(exitstatus: 0, stdout: "", stderr: "")
    calls = []
    Thread.current[:open3_capture3_stub] = {
      calls: calls,
      stdout: stdout,
      stderr: stderr,
      exitstatus: exitstatus
    }
    yield calls
  ensure
    Thread.current[:open3_capture3_stub] = nil
  end

  def run_cli_with_capture3_stub(args, exitstatus: 0, stdout: "", stderr: "")
    status = out = err = nil
    calls = nil
    with_capture3_stub(exitstatus: exitstatus, stdout: stdout, stderr: stderr) do |stub_calls|
      calls = stub_calls
      status, out, err = run_cli(args)
    end
    [status, out, err, calls]
  end

  def assert_cli_success(status, err)
    assert_equal 0, status
    assert_equal "", err
  end

  def assert_systemctl_call(calls, index, expected_args)
    args, kwargs = calls.fetch(index)
    assert_equal expected_args, args
    assert_equal({}, kwargs)
  end

  def assert_systemctl_call_starts_with(calls, index, prefix, includes: nil)
    args, kwargs = calls.fetch(index)
    assert_equal prefix, args.take(prefix.length)
    assert_equal({}, kwargs)
    return if includes.nil?

    Array(includes).each { |expected| assert_includes args, expected }
  end

  def with_project_dir
    Dir.mktmpdir("wheneverd-project-") do |tmp|
      project_dir = File.join(tmp, "myapp")
      FileUtils.mkdir_p(project_dir)
      Dir.chdir(project_dir) { yield project_dir }
    end
  end

  def with_inited_project_dir
    with_project_dir do |project_dir|
      assert_equal 0, run_cli(["init"]).first
      yield project_dir
    end
  end

  def expected_units(identifier: "demo", schedule_path: File.join("config", "schedule.rb"))
    schedule = Wheneverd::DSL::Loader.load_file(File.expand_path(schedule_path))
    Wheneverd::Systemd::Renderer.render(schedule, identifier: identifier)
  end

  def expected_timer_basenames(identifier: "demo",
                               schedule_path: File.join("config", "schedule.rb"))
    expected_units(identifier: identifier, schedule_path: schedule_path)
      .select { |unit| unit.kind == :timer }
      .map(&:path_basename)
      .uniq
  end

  def expected_service_basenames(identifier: "demo",
                                 schedule_path: File.join("config", "schedule.rb"))
    expected_units(identifier: identifier, schedule_path: schedule_path)
      .select { |unit| unit.kind == :service }
      .map(&:path_basename)
      .uniq
  end
end
