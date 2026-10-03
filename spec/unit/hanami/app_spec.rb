# frozen_string_literal: true

require "open3"

RSpec.describe Hanami, ".app" do
  after { Hanami.remove_instance_variable(:@_app) if Hanami.instance_variable_defined?(:@_app) }

  context "app is not yet configured" do
    before { Hanami.remove_instance_variable(:@_app) if Hanami.instance_variable_defined?(:@_app) }

    it "raises an error" do
      expect { Hanami.app }.to raise_error(Hanami::AppLoadError, /not yet configured/)
    end
  end

  context "app is configured" do
    let(:app_class) { Class.new }

    before { Hanami.instance_variable_set(:@_app, app_class) }

    it "returns the app class" do
      expect(Hanami.app).to be(app_class)
    end

    # Runs in a subprocess, since creating a Ractor switches the whole process into multi-Ractor
    # mode, which breaks Zeitwerk in later specs.
    it "returns the app class from a non-main Ractor", if: defined?(Ractor) do
      script = <<~RUBY
        Warning[:experimental] = false
        require "hanami"
        App = Class.new
        Hanami.instance_variable_set(:@_app, App)
        print Ractor.new { Hanami.app.equal?(App) }.value
      RUBY

      output, status = Open3.capture2e(RbConfig.ruby, "-I", File.expand_path("../../../lib", __dir__), "-e", script)

      expect(status).to be_success, output
      expect(output).to eq("true")
    end
  end
end
