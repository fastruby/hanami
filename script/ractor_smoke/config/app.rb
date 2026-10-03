require "hanami"
module RactorApp
  class App < Hanami::App
    config.logger.stream = File::NULL
  end
end
