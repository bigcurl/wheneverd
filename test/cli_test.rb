# frozen_string_literal: true

require_relative "test_helper"
require "wheneverd/cli"

class CLITest < Minitest::Test
  def test_help_prints_usage_and_exits_zero
    out, err = capture_io { assert_equal 0, Wheneverd::CLI.run(["--help"]) }

    assert_includes out, "Usage: wheneverd"
    assert_equal "", err
  end

  def test_invalid_option_exits_two
    _out, err = capture_io { assert_equal 2, Wheneverd::CLI.run(["--definitely-not-a-real-flag"]) }

    assert_includes err, "invalid option"
  end
end

