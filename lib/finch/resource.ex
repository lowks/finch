defmodule Finch.Resource do
  require Jazz
  import Phoenix.Controller

  def default_opts do
    %{
      :before => [],
      :after => [],
      :exclude => []
    }
  end


  defmacro __using__(res_opts \\ []) do

    quote do

      @options Enum.into(unquote(res_opts), Finch.Resource.default_opts)

      use Phoenix.Controller, @options
      use Jazz
      import Finch.Resource
      import Ecto.Query

      def bad_request, do: 400
      def unauthorized, do: 401
      def forbidden, do: 403
      def not_found, do: 404
      def created, do: 201
      def accepted, do: 202
      def ok, do: 200
     


      def id_field, do: :id
      def get_id(params), do: String.to_integer(params[id_field])


      @doc """
        Returns the size of the slice of models that will be returned
        on GETting an :index endpoint
      """
      def page_size, do: 40


      @doc """
        Internal dispatch method that runs the middleware before the 
        request is handled, calls the handler, and then calls the middleware
        after the request is handled. 

        Catches exceptions thrown when access to a resource fails due to one of the
        following cases:
          :bad_request
          :unauthorized
          :forbidden
          :not_found

      """
      def dispatch(verb, conn, params) do
        %{:before => before_request, :after => after_request} = @options
        #convert the string => val map to atom => val map
        params =  Enum.into(Enum.map(params, 
          fn {key, value} -> 
            {String.to_atom(key), value} 
          end), Map.new)
        try do
          request = {verb, conn, params, __MODULE__, %{}}

          request = Enum.reduce(before_request, request, fn(layer, req) -> layer.handle(req) end)
            |> handle
            |> Tuple.insert_at(0, verb)
            |> Tuple.insert_at(4, __MODULE__)

          #{verb, conn, status, result, module}
          
          {_, conn, status, result, _} = Enum.reduce(after_request, 
            request, fn(layer, res) -> layer.handle(res) end)
          json conn, status, serialize(result)
        catch
          {:bad_request, errors} -> json conn, bad_request, serialize(errors)
          {:unauthorized, errors} -> json conn, unauthorized, serialize(errors)
          {:forbidden, errors} -> json conn, forbidden, serialize(errors)
          {:not_found, errors} -> json conn, not_found, serialize(errors)
        end
      end

      def index(conn, params), do: dispatch(:index, conn, params)
      def show(conn, params), do: dispatch(:show, conn, params)
      def create(conn, params), do: dispatch(:create, conn, params)
      def update(conn, params), do: dispatch(:update, conn, params)
      def destroy(conn, params), do: dispatch(:destroy, conn, params)




      @doc """
        The where clause for a specific request type. This allows you to tap 
        into the chain where the query expression is created and implement
        specific functionality. By default for :show it just does a lookup on the 
        id attribute
      """
      def tap(q, :where, {:show, _, params, _, _}) do
        id = get_id(params)
        q |> where([i], field(i, ^id_field) == ^id)
      end

      def tap(q, :where, _), do: q

      @doc """
        Just like the tap/3 method for :where, this allows you to tap into the 
        chain where the query expression is created and implement specific functionality
        for model selection
      """
      def tap(q, :select, _), do: q |> select([i], i)

      @doc """
        Composes the model, where, and selection parts of the request handling. You 
        can override this to do whatever query you want. If you override this, you will
        likely need to implement index_size/1 so the meta.count value in the :index 
        endpoint is correct
      """
      def query(request) do
        model |> tap(:where, request) |> tap(:select, request)
      end


      @doc """
        Returns the count of models for an index request
      """
      def index_size(request) do
        model
          |> tap(:where, request) 
          |> select([i], count(i.id))
          |> repo.all
      end

      @doc """
        Ensures that a model exists. If it does not exist, a :not_found
        exception is thrown. 
      """
      defp ensure_exists thing do
        if is_nil thing do
          throw {:not_found, %{error: "That resource doesn't exist"}}
        end
        thing
      end

      ##
      # get the actual size (int) of the index
      def index_count(request) do
        case index_size(request) do
          [] -> 0
          [num] -> num
        end
      end


      @doc """
        Handles the :index endpoint. Returns a response with data and meta
        attributes. data is a slice of models page_size/0 long, and meta contains
        the total count of models, number of pages in total, and the next page. 
      """
      def handle({:index, conn, params, module, bundle}) do
        request = {:index, conn, params, module, bundle}
        offset = (Dict.get(params, :page, "0") |> String.to_integer) * page_size
        filter = Dict.get(params, :filter, false)
        order = Dict.get(params, :order, false)

        expr = query request
        if filter do
          [fname, value] = String.split(filter, ":")
          fname = String.to_atom fname
          value = "%" <> value <> "%"
          expr = expr |> where([u], ilike(field(u, ^fname), ^value))
        end


        if order do
          #implement backwards ordering too...
          order = String.to_atom order
          expr = expr |> order_by([u], desc: field(u, ^order))
        end

        data = expr
          |> limit(page_size)
          |> offset(offset)
          |> repo.all 
          |> to_serializable


        count = index_count(request)
        pages = trunc(count / page_size)
        result = %{:meta => %{
          :pages => pages, 
          :count => count, 
          :next => trunc((page_size + offset) / page_size)
        }, :data => data}
        {conn, ok, result}
      end


      @doc """
        Creates a model and saves it to the database. 
      """
      def handle({:create, conn, params, module, bundle}) do
        if model.has_user? and Dict.get(bundle, :user, false) do
          params = Dict.put(params, :user_id, bundle[:user].id)
        end
        thing = model.allocate(params) |> repo.insert |> to_serializable
        {conn, created, thing}
      end

      @doc """
        Gets a single model from the database and returns it
      """
      def handle({:show, conn, params, module, bundle}) do
        result = model
          |> tap(:where, {:show, conn, params, module, bundle})
          |> tap(:select, {:show, conn, params, module, bundle})
          |> repo.all 
          |> List.first
          |> ensure_exists
        {conn, ok, to_serializable result}
      end

      @doc """
        Gets a model from the database, sets the parameters that were passed in 
        the request, and saves it to the database.
      """
      def handle({:update, conn, params, module, bundle}) do
        id = get_id(params)
        row = model.allocate(params)
        try do
          Ecto.Model.put_primary_key(row, id) |> repo.update
        rescue
          _ -> throw {:not_found, %{error: "That resource doesn't exist"}}
        end
        {conn, accepted, to_serializable(row)}
      end

      @doc """
        Delets a model from the database
      """
      def handle({:destroy, conn, params, module, bundle}) do
        id = get_id(params)
        result = model
          |> tap(:where, {:show, conn, params, module, bundle})
          |> tap(:select, {:show, conn, params, module, bundle})
          |> repo.all
          |> List.first
          |> ensure_exists

        repo.delete(result)
        {conn, accepted, to_serializable result}
      end


      @doc """
        Returns the serializer to be used 
      """
      def serializer, do: Finch.Serializer

      @doc """
        Converts a list or single ecto model into a map, which
        can then be JSONified by a JSON library
      """
      def to_serializable(thing) do
        serializer.to_serializable(thing, model, @options)
      end

      @doc """
        Do the actual JSON conversion
      """
      def serialize(thing) do
        Jazz.encode!(thing)
      end


      defoverridable [
        to_serializable: 1,
        handle: 1,
        serializer: 0,
        index_count: 1,
        index_size: 1,
        ensure_exists: 1,
        tap: 3,
        query: 1,
        id_field: 0,
        get_id: 1,
        page_size: 0
      ]
    end
  end
end
