

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



defmodule Finch.Test.RouteTest do
	use Finch.Test.Case
	use ExUnit.Case
	use PlugHelper
	use Finch.Test.RouterHelper

	test "should be able to get a list of foos" do
		result = call(Router, :get, "/api/v1/foo")
		:io.format("RESULT ~p~n", [result])
	end
end 