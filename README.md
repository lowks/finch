finch
=====

### don't use this because it's going to change to use the plug spec and ecto model validations

this is a little thing that sits in between phoenix and ecto that makes building CRUDy REST APIs really simple.
It does not offer many features. It aims to be really small and easy to understand. 


Things it will do: 
  *  basic CRUD operations for ecto models
  *  separation of your model and API resource layer
  *  filtering, ordering, paging of models at index endpoints
  *  model validation with extensible validation middleware
  *  basic auth with apikeys
  *  sideloading resource relationships

Things it won't do: 
  *  writable resource nesting (maybe for the future)
  *  XML/Protobufs/SOAP/whatever. Only json.
  *  cookie auth. use an api key. you could write a middleware layer that does this though. 
  *  integration with anything other than ecto or phoenix
  *  make you a sandwich



## usage

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



## filtering, paging, and ordering


### paging
By default, a ```GET``` request to an index endpoint will page the models. The default page size is 40, but you can implement ```page_size/0``` to override that. Adding the ```?page=some_number``` url parameter will fetch the page you specify. index endpoints return a meta object that gives you information relevant to paging. 


### filtering
You can filter on fields as well, which just does a case insensitive like query. you
can change how the filtering happens by overriding ```apply_filters/2``` in your 
resource.

Adding ```?filter=field_name:value``` will select the models where ```field_name```
is like ```value```

### ordering
You can order the index endpoint. Add ```?order=field_name``` to get 
models sorted by ```field_name```. To reverse the order, add a - (minus sign)
in front of the ```field_name```


Paging, filtering, ordering all can be combined in a request. All of them
can be overridden for custom behavior. 


## middleware
you can add middleware that runs before and after the request to your resources. 

### Validators
using the same router and Foo model as above, you could so something like this

```elixir

defmodule MyCoolApp.FooValidator do
  use Finch.Middleware.ModelValidator

  def validate_field(_, :title, val) do
    if val == "can you" do
      throw {:bad_request, %{:errors => %{:title => "can you not"}}}
    end
    {:title, val}
  end

  def validate_field(verb, name, val), do: super(verb, name, val)

end


defmodule MyCoolApp.Resources.Foo do

  def repo, do: MyCoolApp.Repo
  def model, do: MyCoolApp.Models.Foo

  use Finch.Resource, [
    before: [MyCoolApp.FooValidator]
  ]
end


```

POSTing the following json 
```json
{
  "title" : 1,
  "text": "some text"
}

```

to the ```/api/v1/foo``` endpoint would result in a 400 BadRequest with the following message

```json
{
  "errors" : {
    "title": "This needs to be a string"
  }
}
```

##### custom validation

you can also implement custom validation on fields. the ```validate_field/3``` function 
gets run for each field. in this case posting the following 

```json
{
  "title" : "can you",
  "text": "some text"
}

```
to ```/api/v1/foo``` would result in a 400 BadRequest with the following message
```json
{
  "errors" : {
    "title": "can you not"
  }
}
```


