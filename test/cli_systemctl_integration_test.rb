# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_subprocess_test_helpers"

class CLISystemctlIntegrationTest < Minitest::Test
  include CLISubprocessTestHelpers

  def test_reload_invokes_systemctl_via_path_injection
    with_temp_project_dir { |project_dir| assert_reload_invokes_systemctl(project_dir) }
  end

  private

  def assert_reload_invokes_systemctl(project_dir)
    init_schedule(project_dir)
    with_fake_systemctl(project_dir) do |env, log_path|
      run_reload(project_dir, env)
      assert_systemctl_log_includes_expected_calls(log_path)
    end
  end

  def run_reload(project_dir, env)
    unit_dir = File.join(project_dir, "tmp_units")
    status, _out, err = run_exe(
      ["reload", "--identifier", "demo", "--unit-dir", unit_dir],
      chdir: project_dir,
      env: env
    )
    assert_equal 0, status
    assert_equal "", err
  end

  def init_schedule(project_dir)
    status, out, err = run_exe(["init"], chdir: project_dir)
    assert_equal 0, status
    assert_equal "", err
    assert_includes out, "Wrote schedule template"
  end

  def with_fake_systemctl(project_dir)
    bin_dir = File.join(project_dir, "tmp_bin")
    FileUtils.mkdir_p(bin_dir)
    log_path = File.join(project_dir, "systemctl.log")

    write_fake_systemctl(File.join(bin_dir, "systemctl"))

    env = {
      "PATH" => [bin_dir, ENV.fetch("PATH", "")].join(File::PATH_SEPARATOR),
      "SYSTEMCTL_LOG" => log_path
    }
    yield env, log_path
  end

  def write_fake_systemctl(path)
    File.write(
      path,
      <<~RUBY
        #!/usr/bin/env ruby
        # frozen_string_literal: true

        log_path = ENV.fetch("SYSTEMCTL_LOG")
        File.open(log_path, "a") { |f| f.puts(ARGV.join(" ")) }
        exit 0
      RUBY
    )
    FileUtils.chmod(0o755, path)
  end

  def assert_systemctl_log_includes_expected_calls(log_path)
    log = File.read(log_path)
    assert_includes log, "--user --no-pager daemon-reload"
    assert_includes log, "--user --no-pager restart"
    assert_includes log, "wheneverd-demo-e0-j0.timer"
  end
end
