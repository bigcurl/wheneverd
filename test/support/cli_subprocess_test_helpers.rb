# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "tmpdir"

module CLISubprocessTestHelpers
  def with_temp_project_dir
    Dir.mktmpdir("wheneverd-e2e-") do |tmp|
      project_dir = File.join(tmp, "myapp")
      FileUtils.mkdir_p(project_dir)
      yield project_dir
    end
  end

  def exe_path
    File.expand_path("../../exe/wheneverd", __dir__)
  end

  def run_exe(args, chdir:, env: {})
    stdout, stderr, status = Open3.capture3(env, RbConfig.ruby, exe_path, *args, chdir: chdir)
    [status.exitstatus, stdout, stderr]
  end

  def write_schedule(project_dir, contents)
    path = File.join(project_dir, "config", "schedule.rb")
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, contents)
  end

  def find_executable(name)
    ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
      candidate = File.join(dir, name)
      return candidate if File.file?(candidate) && File.executable?(candidate)
    end
    nil
  end
end
