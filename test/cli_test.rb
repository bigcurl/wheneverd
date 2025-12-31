# frozen_string_literal: true

require_relative "test_helper"
require "wheneverd/cli"

class CLITest < Minitest::Test
  def test_help_prints_usage_and_exits_zero
    out, err = capture_io { Wheneverd::CLI.run("wheneverd", ["--help"]) }

    assert_includes out, "Usage:"
    assert_includes out, "wheneverd [OPTIONS]"
    assert_equal "", err
  end

  def test_version_prints_version_and_exits_zero
    out, err = capture_io { assert_equal 0, Wheneverd::CLI.run("wheneverd", ["--version"]) }

    assert_includes out, Wheneverd::VERSION
    assert_equal "", err
  end

  def test_no_args_exits_one_and_prints_help_to_stderr
    out, err = capture_io { assert_equal 1, Wheneverd::CLI.run("wheneverd", []) }

    assert_equal "", out
    assert_includes err, "Usage:"
    assert_includes err, "wheneverd [OPTIONS]"
  end

  def test_verbose_exits_one_and_prints_scaffold_message
    out, err = capture_io { assert_equal 1, Wheneverd::CLI.run("wheneverd", ["--verbose"]) }

    assert_equal "", out
    assert_includes err, "wheneverd: not implemented yet"
    assert_includes err, "Usage:"
    assert_includes err, "wheneverd [OPTIONS]"
  end

  def test_invalid_option_exits_one_and_prints_error
    out, err = capture_io do
      exit_error = assert_raises(SystemExit) { Wheneverd::CLI.run("wheneverd", ["--definitely-not-a-real-flag"]) }

      assert_equal 1, exit_error.status
    end

    assert_equal "", out
    assert_includes err, "ERROR:"
    assert_includes err, "--definitely-not-a-real-flag"
    assert_includes err, "See:"
  end
end
