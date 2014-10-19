
defmodule FilterTest.Resources.Foo do
  use Finch.Resource
  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Foo
end

defmodule Validator.Validator do
  use Finch.Middleware.ModelValidator, [only: [:create, :update]]
end


defmodule FilterTest.Resources.Bar do

  use Finch.Resource, [
    before: [
      Validator.Validator
    ]
  ]
  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Bar

end



defmodule FilterTest.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/foo", FilterTest.Resources.Foo, except: []
      resources "/bar", FilterTest.Resources.Bar, except: []

    end
  end
end



defmodule Finch.Test.FilterTest do
    use ExUnit.Case
    use Finch.Test.Case
    use PlugHelper
    use Finch.Test.RouterHelper
    alias FilterTest.Router


    test "no search param gives back all the foos" do
      headers = %{"Content-Type" => "application/json"}

      for n <- 1..5 do
        params = %{"title" => "hello #{n}", "text" => "world #{n}"}
        conn = call(Router, :post, "/api/v1/foo", params, headers)
        assert conn.status == 201
      end

      conn = call(Router, :get, "/api/v1/foo")
      %{"data" => foos, "meta" => %{"count" => count}} = Jazz.decode! conn.resp_body
      assert length(foos) == 5
      assert count == 5
    end


    test "can filter on bools" do
      headers = %{"Content-Type" => "application/json"}

      for n <- 1..5 do
        params = %{
          "a_string" => "hello #{n}", 
          "an_int" => n,
          "a_bool" => (rem(n, 2) == 0),
          "a_dt" => "7/7/2014 8:20:20"
        }
        conn = call(Router, :post, "/api/v1/bar", params, headers)
        assert conn.status == 201
      end

      conn = call(Router, :get, "/api/v1/bar?filter=a_bool:false")
      %{"data" => data, "meta" => %{"count" => count}} = Jazz.decode! conn.resp_body
      assert count == 3
      assert length(data) == 3
    end


    test "can filter on ints" do
      headers = %{"Content-Type" => "application/json"}

      for n <- 1..5 do
        params = %{
          "a_string" => "hello #{n}", 
          "an_int" => n,
          "a_bool" => (rem(n, 2) == 0),
          "a_dt" => "7/7/2014 8:20:20"
        }
        conn = call(Router, :post, "/api/v1/bar", params, headers)
        assert conn.status == 201
      end

      conn = call(Router, :get, "/api/v1/bar?filter=an_int:1")
      %{"data" => [data]} = Jazz.decode! conn.resp_body
      %{"data" => data, "meta" => %{"count" => count}} = Jazz.decode! conn.resp_body
      assert count == 1
      assert length(data) == 1
    end


    test "can filter on some field name" do
      headers = %{"Content-Type" => "application/json"}

      for n <- 1..5 do
        params = %{"title" => "hello #{n}", "text" => "world #{n}"}
        conn = call(Router, :post, "/api/v1/foo", params, headers)
        assert conn.status == 201
      end

      conn = call(Router, :get, "/api/v1/foo?filter=title:hello 3")
      %{"data" => [
        %{
          "title" => "hello 3",
          "text" => "world 3"
        }
      ]} = Jazz.decode! conn.resp_body
    end

    test "filtering is case insensitive and works on substrings" do
      headers = %{"Content-Type" => "application/json"}

      for n <- 1..5 do
        params = %{"title" => "hello #{n}", "text" => "world #{n}"}
        conn = call(Router, :post, "/api/v1/foo", params, headers)
        assert conn.status == 201
      end

      conn = call(Router, :get, "/api/v1/foo?filter=title:HELLO")
      %{"data" => foos, "meta" => %{"count" => count}} = Jazz.decode! conn.resp_body
      assert length(foos) == 5
      assert count == 5
    end

    test "non-matching term returns empty list" do
      headers = %{"Content-Type" => "application/json"}

      for n <- 1..5 do
        params = %{"title" => "hello #{n}", "text" => "world #{n}"}
        conn = call(Router, :post, "/api/v1/foo", params, headers)
        assert conn.status == 201
      end

      conn = call(Router, :get, "/api/v1/foo?filter=title:nothing")
      %{"data" => foos, "meta" => %{"count" => count}} = Jazz.decode! conn.resp_body
      assert length(foos) == 0
      assert count == 0
    end

    

end 