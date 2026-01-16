# frozen_string_literal: true

require_relative "test_helper"

class DSLContextShellTest < Minitest::Test
  def test_shell_requires_every_block
    ctx = Wheneverd::DSL::Context.new(path: "/tmp/config/schedule.rb")
    error = assert_raises(Wheneverd::DSL::LoadError) { ctx.shell("echo hi") }
    assert_includes error.message, "shell() must be called inside every() block"
  end

  def test_shell_requires_string_script
    ctx = Wheneverd::DSL::Context.new(path: "/tmp/config/schedule.rb")
    error = assert_raises(Wheneverd::DSL::LoadError) { ctx.every("1m") { shell(123) } }
    assert_includes error.message, "shell() script must be a String"
  end

  def test_shell_rejects_empty_script
    ctx = Wheneverd::DSL::Context.new(path: "/tmp/config/schedule.rb")
    error = assert_raises(Wheneverd::DSL::LoadError) { ctx.every("1m") { shell("   ") } }
    assert_includes error.message, "shell() script must not be empty"
  end
end
