
defmodule OrderTest.Resources.Foo do
  use Finch.Resource
  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Foo
end



defmodule OrderTest.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/foo", OrderTest.Resources.Foo, except: []
    end
  end
end



defmodule Finch.Test.OrderTest do
    use ExUnit.Case
    use Finch.Test.Case
    use PlugHelper
    use Finch.Test.RouterHelper
    alias OrderTest.Router


    test "can order on some field name" do
      headers = %{"Content-Type" => "application/json"}

      for n <- 1..5 do
        params = %{"title" => "hello #{n}", "text" => "world #{n}"}
        conn = call(Router, :post, "/api/v1/foo", params, headers)
        assert conn.status == 201
      end

      conn = call(Router, :get, "/api/v1/foo?order=id")
      %{"data" => data} = Jazz.decode! conn.resp_body
      ids = Enum.map(data, fn item -> item["id"] end)
      assert ids == Enum.sort ids
    end

    test "can reverse order on some field name by adding a '-' sign" do
      headers = %{"Content-Type" => "application/json"}

      for n <- 1..5 do
        params = %{"title" => "hello #{n}", "text" => "world #{n}"}
        conn = call(Router, :post, "/api/v1/foo", params, headers)
        assert conn.status == 201
      end

      conn = call(Router, :get, "/api/v1/foo?order=-id")
      %{"data" => data} = Jazz.decode! conn.resp_body
      ids = Enum.map(data, fn item -> item["id"] end)
      assert ids == Enum.sort(ids, &(&1 > &2))
    end
    

end 