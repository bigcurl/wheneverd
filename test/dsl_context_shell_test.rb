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

  def test_service_accepts_shell_command
    ctx = Wheneverd::DSL::Context.new(path: "/tmp/config/schedule.rb")
    ctx.service("live-poller", shell: "bundle exec bin/live")

    service = ctx.schedule.services.fetch(0)
    assert_equal "live-poller", service.name
    assert_equal ["/bin/bash", "-lc", "bundle exec bin/live"], service.command.argv
  end

  def test_service_requires_command_or_shell
    ctx = Wheneverd::DSL::Context.new(path: "/tmp/config/schedule.rb")
    error = assert_raises(Wheneverd::DSL::LoadError) { ctx.service("live-poller") }
    assert_includes error.message, "service() requires command: or shell:"
  end

  def test_service_rejects_command_and_shell_together
    ctx = Wheneverd::DSL::Context.new(path: "/tmp/config/schedule.rb")
    error = assert_raises(Wheneverd::DSL::LoadError) do
      ctx.service("live-poller", command: "bin/live", shell: "bin/live")
    end
    assert_includes error.message, "service() accepts command: or shell:, not both"
  end

  def test_service_wraps_validation_errors_as_load_errors
    ctx = Wheneverd::DSL::Context.new(path: "/tmp/config/schedule.rb")
    error = assert_raises(Wheneverd::DSL::LoadError) do
      ctx.service("live-poller", command: "bin/live", service: { "Bad-Key" => "1" })
    end
    assert_includes error.message, "Invalid service setting name"
  end

  def test_shell_rejects_empty_script
    ctx = Wheneverd::DSL::Context.new(path: "/tmp/config/schedule.rb")
    error = assert_raises(Wheneverd::DSL::LoadError) { ctx.every("1m") { shell("   ") } }
    assert_includes error.message, "shell() script must not be empty"
  end
end
