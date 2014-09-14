finch
=====

### don't try to use this the API suxxx and i'm cleaning it up right now

this is a little thing that sits in between phoenix and ecto that makes building CRUDy REST APIs really simple


### usage

```elixir

defmodule MyCoolApp.Resources.Foo do

  def repo, do: MyCoolApp.Repo
  def model, do: MyCoolApp.Models.Foo

  use Finch.Resource
end


defmodule Write.Router do
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
| ------------- | ------------- |
| GET  | /api/v1/foo  | list all the foos |
| POST  | /api/v1/foo  | make a foo |
| GET  | /api/v1/foo/#{id}  | get a foo with id |
| PUT  | /api/v1/foo/#{id}  | update a foo with id |
| DELETE  | /api/v1/foo/#{id}  | delete a foo with id |
