module RactorApp
  class Routes < Hanami::Routes
    root to: "home.show"
    get "/static", to: ->(env) { [200, {}, ["static"]] }
  end
end
