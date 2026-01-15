# frozen_string_literal: true

require "simplecov"
require "open3"

SimpleCov.start do
  add_filter "/test/"
  minimum_coverage ENV.fetch("MINIMUM_COVERAGE", "100").to_i
end

module Open3Capture3TestStub
  Status = Struct.new(:exitstatus) do
    def success?
      exitstatus.zero?
    end
  end

  def capture3(*cmd, **kwargs)
    stub = Thread.current[:open3_capture3_stub]
    return super unless stub

    stub.fetch(:calls) << [cmd, kwargs]
    [
      stub.fetch(:stdout, ""),
      stub.fetch(:stderr, ""),
      Status.new(stub.fetch(:exitstatus, 0))
    ]
  end
end

Open3.singleton_class.prepend(Open3Capture3TestStub)

require "minitest/autorun"
require "wheneverd"
