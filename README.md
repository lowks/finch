finch
=====

this is a little thing that sits in between phoenix and ecto that makes building CRUDy REST APIs really simple


### usage

```elixir


defmodule MyCoolApp.Models.Foo do
  use Finch.Model

  schema "foos" do
    field :title, :string
    field :text, :string
  end

end

defmodule MyCoolApp.Resources.Foo do
  use Finch.Resource
  
  def repo, do: MyCoolApp.Repo
  def model, do: MyCoolApp.Models.Foo

end


defmodule MyCoolApp.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/foo", MyCoolApp.Resources.Foo
    end
  end
end


```

The code above will grant you the following powers...


| method  | route | result |
| ------------- | ------------| ------------- |
| GET  | /api/v1/foo  | list all the foos |
| POST  | /api/v1/foo  | make a foo |
| GET  | /api/v1/foo/#{id}  | get a foo with id |
| PUT  | /api/v1/foo/#{id}  | update a foo with id |
| DELETE  | /api/v1/foo/#{id}  | delete a foo with id |



### middleware
you can add middleware that runs before and after the request to your resources. 

```elixir

defmodule MyCoolApp.FooValidator do
  use Finch.Middleware.ModelValidator
end


defmodule MyCoolApp.Models.Foo do
  use Finch.Model

  schema "foos" do
    field :title, :string
    field :text, :string
  end

end

defmodule MyCoolApp.Resources.Foo do

  def repo, do: MyCoolApp.Repo
  def model, do: MyCoolApp.Models.Foo

  use Finch.Resource, [
    before: [MyCoolApp.FooValidator]
  ]
end


defmodule MyCoolApp.Router do
  use Phoenix.Router

  scope path: "/api" do
    scope path: "/v1" do
      resources "/foo", MyCoolApp.Resources.Foo
    end
  end
end

```

POSTing the following json 
```json
{
  "title" : 1,
  "text": "some text"
}

```

to the /api/v1/foo endpoint would result in a 400 BadRequest with the following message

```json
{
  "errors" : {
    "title": "This needs to be a string"
  }
}
```
