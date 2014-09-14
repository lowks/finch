

defmodule EmptyRead.Resources.Foo do
  use Finch.Resource, []

  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Foo

end


defmodule EmptyRead.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/foo", EmptyRead.Resources.Foo, except: []
    end
  end
end



defmodule Finch.Test.EmptyRead do
    use ExUnit.Case
    use Finch.Test.Case
    use PlugHelper
    use Finch.Test.RouterHelper
    alias EmptyRead.Router

    test "should be able to get an empty list of foos" do
      conn = call(Router, :get, "/api/v1/foo")
      assert conn.status == 200
      js = Jazz.decode! conn.resp_body
      %{"data" => data, "meta" => %{"count" => count, "pages" => pages}} = js
      assert data == []
      assert count == 0
      assert pages == 0
    end

    test "should get a 404 for showing a thing that doesn't exist" do
      conn = call(Router, :get, "/api/v1/foo/1")
      assert conn.status == 404
      js = Jazz.decode! conn.resp_body
      %{"error" => msg} = js 
    end


    test "should get a 404 for deleting a thing that doesn't exist" do
      conn = call(Router, :delete, "/api/v1/foo/1")
      assert conn.status == 404
      js = Jazz.decode! conn.resp_body
      %{"error" => msg} = js 
    end

    test "should get a 404 for updating a thing that doesn't exist" do
      conn = call(Router, :put, "/api/v1/foo/1")
      IO.inspect conn.resp_body
      assert conn.status == 404
      js = Jazz.decode! conn.resp_body
      %{"error" => msg} = js 
    end


end 