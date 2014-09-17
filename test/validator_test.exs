defmodule Validator.Validator do
  use Finch.Middleware.ModelValidator, [only: [:create, :update]]

  
  def validate_field(:index, :a_string, _) do
      throw {:bad_request, "This should never happen"}
  end

  def validate_field(_, :a_string, val) do
    if val == "can you" do
      throw {:bad_request, %{:errors => %{:a_string => "can you not"}}}
    end
    {:a_string, val}
  end



  def validate_field(verb, name, val), do: super(verb, name, val)
end


defmodule Validator.AnotherValidator do
  use Finch.Middleware.ModelValidator, [except: [:index]]

  def validate_field(:index, :a_string, _) do
      throw {:bad_request, "This should never happen"}
  end

  def validate_field(verb, name, val), do: super(verb, name, val)
end


defmodule Validator.Resources.Bar do

  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Bar

  use Finch.Resource, [
    before: [
      Validator.Validator
    ]
  ]
end


defmodule Validator.Resources.DoubleBar do

  def repo, do: Finch.Test.TestRepo
  def model, do: Finch.Test.Bar

  use Finch.Resource, [
    before: [
      Validator.Validator, 
      Validator.AnotherValidator
    ]
  ]
end


defmodule Validator.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/bar", Validator.Resources.Bar, except: []
      resources "/double_validation", Validator.Resources.DoubleBar, except: []

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


    test "validation is not run for verbs not specified in 'only' options" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "hello",
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => "7/7/2014 8:20:20"
       }
      conn = call(Router, :get, "/api/v1/bar", params, headers)
      assert conn.status == 200
    end

    test "validation is not run for verbs specified in 'except' options" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "hello",
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => "7/7/2014 8:20:20"
       }
      conn = call(Router, :get, "/api/v1/double_validation", params, headers)
      assert conn.status == 200
    end

    test "custom field validation" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "can you",
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => "7/7/2014 8:20:20"
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 400
      IO.puts conn.resp_body
      %{"errors" => %{"a_string" => "can you not"}} = Jazz.decode! conn.resp_body
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

    test "datetime adaption" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "a_string",
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => "720"
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 400
      %{"errors" => %{"a_dt" => "Invalid date format"}} = Jazz.decode! conn.resp_body
    end

    test "datetime validation" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "a_string",
        "an_int" => 1,
        "a_bool" => true,
        "a_dt" => 1
       }

      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 400
      %{"errors" => %{"a_dt" => "This needs to be a string"}} = Jazz.decode! conn.resp_body
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
        "a_dt" => "Invalid date format"
        }} = Jazz.decode! conn.resp_body
    end

    test "valid datetime works" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "a_string",
        "an_int" => 1,
        "a_bool" => false,
        "a_dt" => "7/7/2014 2:52:20"
       }
      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 201
      %{"a_dt" => a_dt} = Jazz.decode! conn.resp_body
      assert a_dt == "7/7/2014 2:52:20"
    end

    test "missing fields is a bad request" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "an_int" => 1,
        "a_bool" => false,
        "a_dt" => "7/7/2014 2:52:20"
       }
      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 400
      %{"errors" => 
        %{
          "a_string" => "This needs to be a string"
        }
      } = Jazz.decode! conn.resp_body
    end

    test "extra fields works fine" do
      headers = %{"Content-Type" => "application/json"}
      params = %{
        "a_string" => "hello",
        "an_extra_field" => "Something",
        "an_int" => 1,
        "a_bool" => false,
        "a_dt" => "7/7/2014 2:52:20"
       }
      conn = call(Router, :post, "/api/v1/bar", params, headers)
      assert conn.status == 201
      params = Jazz.decode! conn.resp_body
    end

end 