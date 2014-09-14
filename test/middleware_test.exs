defmodule MiddlewareTest.Unauthorized do
  use Finch.Middleware.ModelValidator

  def handle({:create, _, _, _, _}) do
    throw {:unauthorized, %{:errors => "can you not"}}
  end

  def handle({:index, conn, status, result, module}) do
    {:index, conn, status, ["huehuehue"], module}
  end
end

defmodule MiddlewareTest.Resources.BeforeFoo do
  use Finch.Resource, [
    before: [MiddlewareTest.Unauthorized]
  ]

  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Foo

end

defmodule MiddlewareTest.Resources.AfterFoo do
  use Finch.Resource, [
    after: [MiddlewareTest.Unauthorized]
  ]

  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Foo

end


defmodule MiddlewareTest.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/beforefoo", MiddlewareTest.Resources.BeforeFoo, except: []
      resources "/afterfoo", MiddlewareTest.Resources.AfterFoo, except: []

    end
  end
end



defmodule Finch.Test.MiddlewareTest do
    use ExUnit.Case
    use Finch.Test.Case
    use PlugHelper
    use Finch.Test.RouterHelper
    alias MiddlewareTest.Router


    test "can throw an error before the request" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "title" => "hello",
        "text" => "world"
       }

      conn = call(Router, :post, "/api/v1/beforefoo", params, headers)
      assert conn.status == 401
    end

    test "can throw an error after the request" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "title" => "hello",
        "text" => "world"
       }

      conn = call(Router, :post, "/api/v1/afterfoo", params, headers)
      assert conn.status == 401
    end

    test "middleware runs after the request, can modify result" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "title" => "hello",
        "text" => "world"
       }
      conn = call(Router, :get, "/api/v1/afterfoo", params, headers)
      assert conn.status == 200
      ["huehuehue"] = Jazz.decode! conn.resp_body
    end


end 