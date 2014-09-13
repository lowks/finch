
defmodule Write.Resources.Foo do

  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Foo

  use Finch.Resource, []
end


defmodule Write.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/foo", Write.Resources.Foo, except: []
    end
  end
end



defmodule Finch.Test.Write do
    use ExUnit.Case
    use Finch.Test.Case
    use PlugHelper
    use Finch.Test.RouterHelper
    alias Write.Router


    test "should be able to create a foo" do
      headers = %{"Content-Type" => "application/json"}
      params = %{"title" => "hello", "text" => "world"}

      conn = call(Router, :post, "/api/v1/foo", params, headers)
      assert conn.status == 201

      %{"title" => hello, "text" => world} = Jazz.decode! conn.resp_body
      assert hello == "hello"
      assert world == "world"
    end


    test "should be able to update a foo" do
      headers = %{"Content-Type" => "application/json"}
      params = %{"title" => "hello", "text" => "world"}

      conn = call(Router, :post, "/api/v1/foo", params, headers)
      assert conn.status == 201

      %{"title" => hello, "text" => world, "id" => id} = Jazz.decode! conn.resp_body

      params = %{"title" => "foo", "text" => "bar"}
      conn = call(Router, :put, "api/v1/foo/#{id}", params, headers)
      assert conn.status == 202

      %{"title" => foo, "text" => bar, "id" => id} = Jazz.decode! conn.resp_body
      assert foo == "foo"
      assert bar == "bar"
    end


end 