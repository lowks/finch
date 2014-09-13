defmodule Validator.Validator do
  use Finch.Middleware.ModelValidator
end


defmodule Validator.Resources.Bar do

  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Bar

  use Finch.Resource, [
    middleware: [
      Validator.Validator
    ]
  ]
end


defmodule Validator.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/bar", Validator.Resources.Bar, except: []
    end
  end
end



defmodule Finch.Test.Validator do
    use ExUnit.Case
    use Finch.Test.Case
    use PlugHelper
    use Finch.Test.RouterHelper
    alias Validator.Router


    test "correct values create a bar" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "hello",
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => "7/7/2014 8:20:20"
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 201

      %{
        "a_string" => "hello", 
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => "7/7/2014 8:20:20"
      } = Jazz.decode! conn.resp_body
    end

    test "string validation" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => 2,
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => "7/7/2014 8:20:20"
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 400
      %{"errors" => %{"a_string" => "This needs to be a string"}} = Jazz.decode! conn.resp_body
    end

    test "number validation" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "a_string",
        "an_int" => "not a number",
        "a_bool" => true,
        "a_dt" => "7/7/2014 8:20:20"
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 400
      %{"errors" => %{"an_int" => "This needs to be an integer"}} = Jazz.decode! conn.resp_body
    end


    test "bool validation" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "a_string",
        "an_int" => 1,
        "a_bool" => "not a bool",
        "a_dt" => "7/7/2014 8:20:20"
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 400
      %{"errors" => %{"a_bool" => "This needs to be a boolean"}} = Jazz.decode! conn.resp_body
    end

    test "datetime validation" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "a_string",
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => "720"
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 400
      %{"errors" => %{"a_dt" => "This needs to be a datetime"}} = Jazz.decode! conn.resp_body
    end


    test "multiple invalid fields" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => 1,
        "an_int" => "nan",
        "a_bool" => "not a bool",
        "a_dt" => "720"
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      
      assert conn.status == 400
      %{"errors" => %{
        "a_string" => "This needs to be a string",
        "an_int" => "This needs to be an integer",
        "a_bool" => "This needs to be a boolean",
        "a_dt" => "This needs to be a datetime"
        }} = Jazz.decode! conn.resp_body
    end



end 