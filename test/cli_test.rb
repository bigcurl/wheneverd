# frozen_string_literal: true

require_relative "test_helper"
require "wheneverd/cli"

class CLITest < Minitest::Test
  def test_help_prints_usage_and_exits_zero
    out, err = capture_io { assert_equal 0, Wheneverd::CLI.run(["--help"]) }

    assert_includes out, "Usage: wheneverd"
    assert_equal "", err
  end

  def test_no_args_exits_one_and_prints_help_to_stderr
    out, err = capture_io { assert_equal 1, Wheneverd::CLI.run([]) }

    assert_equal "", out
    assert_includes err, "Usage: wheneverd"
  end

  def test_verbose_exits_one_and_prints_scaffold_message
    out, err = capture_io { assert_equal 1, Wheneverd::CLI.run(["--verbose"]) }

    assert_equal "", out
    assert_includes err, "wheneverd: not implemented yet"
    assert_includes err, "Usage: wheneverd"
  end

  def test_invalid_option_exits_two
    _out, err = capture_io { assert_equal 2, Wheneverd::CLI.run(["--definitely-not-a-real-flag"]) }

    assert_includes err, "invalid option"
  end
end
