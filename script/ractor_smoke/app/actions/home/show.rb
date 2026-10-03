module RactorApp
  module Actions
    module Home
      class Show < RactorApp::Action
        def handle(request, response)
          response.body = "home"
        end
      end
    end
  end
end
