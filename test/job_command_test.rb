# frozen_string_literal: true

require_relative "test_helper"

class JobCommandTest < Minitest::Test
  def test_accepts_argv_and_formats_execstart
    command = Wheneverd::Job::Command.new(command: ["echo", "hello world"])
    assert_equal ["echo", "hello world"], command.argv
    assert_equal "echo \"hello world\"", command.command
  end

  def test_accepts_empty_argv_argument
    command = Wheneverd::Job::Command.new(command: ["printf", "%s", ""])
    assert_equal "printf %s \"\"", command.command
  end

  def test_rejects_invalid_argv
    assert_raises(Wheneverd::InvalidCommandError) { Wheneverd::Job::Command.new(command: []) }
    assert_raises(Wheneverd::InvalidCommandError) { Wheneverd::Job::Command.new(command: ["   "]) }
    assert_raises(Wheneverd::InvalidCommandError) { Wheneverd::Job::Command.new(command: ["echo", 1]) }
  end

  def test_rejects_argv_with_newlines
    error = assert_raises(Wheneverd::InvalidCommandError) do
      Wheneverd::Job::Command.new(command: %W[echo hi\nthere])
    end
    assert_includes error.message, "must not include NUL or newlines"
  end
end
