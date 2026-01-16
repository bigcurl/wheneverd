# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/cli_test_helpers"

class CLIInitTest < Minitest::Test
  include CLITestHelpers

  def test_writes_template_with_shell_and_argv_examples
    with_project_dir do |project_dir|
      status, out, err = run_cli(["init"])
      assert_equal 0, status
      assert_equal "", err
      assert_includes out, "Wrote schedule template to"

      schedule_path = File.join(project_dir, "config", "schedule.rb")
      schedule = File.read(schedule_path)
      assert_includes schedule, "command [\"echo\", \"hello world\"]"
      assert_includes schedule, "shell \"echo hello | sed -e s/hello/hi/\""
    end
  end

  def test_refuses_to_overwrite_without_force
    with_project_dir do
      assert_equal 0, run_cli(["init"]).first

      status, out, err = run_cli(["init"])
      assert_equal 1, status
      assert_equal "", out
      assert_includes err, "already exists"
      assert_includes err, "--force"
    end
  end

  def test_overwrites_with_force
    with_project_dir do |project_dir|
      assert_equal 0, run_cli(["init"]).first

      schedule_path = File.join(project_dir, "config", "schedule.rb")
      File.write(schedule_path, "# custom\n")

      status, out, err = run_cli(["init", "--force"])
      assert_equal 0, status
      assert_equal "", err
      assert_includes out, "Overwrote schedule template to"
      assert_includes File.read(schedule_path), "Supported `every` period forms:"
    end
  end
end
