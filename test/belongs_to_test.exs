
defmodule BelongsToTest.Resources.Foo do
  use Finch.Resource
  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Foo
end

defmodule BelongsToTest.Resources.FooComment do
  use Finch.Resource
  alias Finch.Test.FooComment
  alias Finch.Test.Foo

  def repo, do: Finch.Test.TestRepo
  def model, do: FooComment

  def query({:show, _, params, _, _}) do
    id = String.to_integer params[:id]
    IO.inspect "doing a show query #{id}"
    from fc in FooComment,
      left_join: f in fc.foo,
      where: fc.id == ^id,
      select: assoc(fc, foo: f)
  end

end


defmodule BelongsToTest.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/foo", BelongsToTest.Resources.Foo, except: []
      resources "/foo_comment", BelongsToTest.Resources.FooComment, except: []
    end
  end
end



defmodule Finch.Test.BelongsToTest do
    use ExUnit.Case
    use Finch.Test.Case
    use PlugHelper
    use Finch.Test.RouterHelper
    alias BelongsToTest.Router


    test "can create a foo_comment that references a foo" do
      headers = %{"Content-Type" => "application/json"}

      params = %{"title" => "hello", "text" => "world"}
      conn = call(Router, :post, "/api/v1/foo", params, headers)
      assert conn.status == 201
      %{"id" => id} = Jazz.decode! conn.resp_body

      params = %{"title" => "a foo comment", "foo_id" => id}
      conn = call(Router, :post, "/api/v1/foo_comment", params, headers)
      assert conn.status == 201
      %{"title" => "a foo comment"} = Jazz.decode! conn.resp_body

      IO.inspect conn.resp_body
    end


    test "if you join to the belongs_to relation, you get the entire relation sideloaded into the response" do
      headers = %{"Content-Type" => "application/json"}

      params = %{"title" => "hello", "text" => "world"}
      conn = call(Router, :post, "/api/v1/foo", params, headers)
      assert conn.status == 201
      %{"id" => id} = Jazz.decode! conn.resp_body

      params = %{"title" => "a foo comment", "foo_id" => id}
      conn = call(Router, :post, "/api/v1/foo_comment", params, headers)
      assert conn.status == 201
      %{"id" => foo_id} = Jazz.decode! conn.resp_body

      conn = call(Router, :get, "/api/v1/foo_comment/#{foo_id}", params, headers)
      %{"foo" => 
        %{
          "title" => "hello", 
          "text" => "world", 
          "id" => id
        }
      } = Jazz.decode! conn.resp_body
    end

    test "if you join to the belongs_to relation, you get the entire relation sideloaded into the response" do
      headers = %{"Content-Type" => "application/json"}

      params = %{"title" => "hello", "text" => "world"}
      conn = call(Router, :post, "/api/v1/foo", params, headers)
      assert conn.status == 201
      %{"id" => id} = Jazz.decode! conn.resp_body

      params = %{"title" => "a foo comment", "foo_id" => id}
      conn = call(Router, :post, "/api/v1/foo_comment", params, headers)
      assert conn.status == 201
      %{"id" => foo_id} = Jazz.decode! conn.resp_body

      conn = call(Router, :get, "/api/v1/foo_comment", params, headers)
      [%{"foo_id" => id}] = Jazz.decode! conn.resp_body
    end


end 