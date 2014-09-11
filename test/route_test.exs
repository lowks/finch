

defmodule RouteTest.Resources.Foo do
  
end


defmodule RouteTest.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/foo", RouteTest.Resources.Foo, except: []
    end
  end
end
