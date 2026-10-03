# Ractor smoke test for Hanami.
#
# Boots a minimal Hanami app in the main Ractor, then checks whether common
# operations work from a non-main Ractor.
#
# Run from the repo root:
#
#   bundle exec ruby script/ractor_smoke/smoke.rb

Warning[:experimental] = false
Dir.chdir(__dir__)
require "rack"
require_relative "config/app"
Hanami.app.prepare
Hanami.app.boot

def env(path) = Rack::MockRequest.env_for(path)

puts "Ruby #{RUBY_VERSION}, hanami #{Hanami::VERSION}"
puts "Main Ractor sanity: #{Hanami.app.rack_app.call(env("/"))[0]}"
puts "-" * 60

tests = {
  "Access Hanami.app in Ractor"            => -> { Ractor.new { Hanami.app.name }.value },
  "Read settings in Ractor"                => -> { Ractor.new { Hanami.app["settings"].greeting }.value },
  "Resolve action from container"          => -> { Ractor.new { Hanami.app["actions.home.show"].class.name }.value },
  "Action.new in Ractor"                   => -> { Ractor.new { RactorApp::Actions::Home::Show.new.call({})[0] }.value },
  "Call rack_app (GET /) in Ractor"        => -> { Ractor.new { Hanami.app.rack_app.call(Rack::MockRequest.env_for("/"))[0] }.value },
  "Call rack_app (lambda route) in Ractor" => -> { Ractor.new { Hanami.app.rack_app.call(Rack::MockRequest.env_for("/static"))[0] }.value },
  "Ractor.make_shareable(rack_app)"        => -> { Ractor.make_shareable(Hanami.app.rack_app); "shareable" },
  "Pass action instance into Ractor"       => -> { Ractor.new(Hanami.app["actions.home.show"]) { |a| a.call({})[0] }.value },
  "Define Hanami::Action subclass"         => -> { Ractor.new { Class.new(Hanami::Action) { def handle(_, r) = r.body = "x" }.new.call({})[0] }.value },
  "Build Hanami::Router in Ractor"         => -> { Ractor.new { Hanami::Router.new { get "/", to: ->(e) { [200, {}, ["r"]] } }.call(Rack::MockRequest.env_for("/"))[0] }.value },
}

results = tests.map do |name, test|
  print "#{name.ljust(42)} "
  begin
    out = test.call
    puts "OK (#{out.inspect})"
    [name, :ok]
  rescue Ractor::RemoteError => e
    c = e.cause
    puts "FAILED: #{c.class}: #{c.message.lines.first.strip[0, 140]}"
    [name, :fail]
  rescue => e
    puts "FAILED: #{e.class}: #{e.message.lines.first.strip[0, 140]}"
    [name, :fail]
  end
end
puts "-" * 60
puts "#{results.count { _2 == :ok }}/#{results.size} passed"
