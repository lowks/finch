defmodule Finch.Middleware.ModelValidator do
  @verbs [:create, :show, :index, :destroy, :update]


  @doc """
    validate_type/3 takes the type, name and value of the field
    and returns 
      {:ok, name, value} when the field passes validation
      {:error, name, error_message} when the field fails validation

    Validation keeps running through all fields even if the very first
    one fails. If there are errors at the end then a :bad_request
    exception is thrown and is handled by the resource dispatch method, 
    which means no more request handling takes place. 
  """
  def validate_type(:integer, name, value) when is_integer(value), do: {:ok, name, value}
  def validate_type(:integer, name, _), do: {:error, name, "This needs to be an integer"}


  def validate_type(:string, name, value) when is_bitstring(value) do
    if String.length(value) > 0 do
      {:ok, name, value}
    else
      {:error, name, "#{name} cannot be blank"}
    end
  end
  def validate_type(:string, name, _), do: {:error, name, "This needs to be a string"}

  def validate_type(:float, name, value) when is_float(value), do: {:ok, name, value}
  def validate_type(:float, name, _), do: {:error, name, "This needs to be a float"}

  def validate_type(:binary, name, value) when is_binary(value), do: {:ok, name, value}
  def validate_type(:binary, name, _), do: {:error, name, "This needs to be a binary"}

  def validate_type(:boolean, name, value) when is_boolean(value), do: {:ok, name, value}
  def validate_type(:boolean, name, _), do: {:error, name, "This needs to be a boolean"}

  def validate_type({:array, _inner_type}, name, value) when is_list(value), do: {:ok, name, value}
  def validate_type({:array, _inner_type}, name, _), do: {:error, name, "This needs to be an array"}

  ##TODO: make the time validation actually work. need to cover...
  # :date
  # :time
  # :virtual
  # 
  
  @doc """
    Validate a datetime field. 
    By default the format is 
    "day/month/year hour:min:sec"

    JSON serialization is configurable via the Jazz.Encoder 
    protocol in the encode method. 

  """
  def validate_type(:datetime, name, value) when is_bitstring(value) do
    try do
      [date, time] = String.split(value, " ")
      [day, month, year] = Enum.map(String.split(date, "/"), &(String.to_integer &1))
      [hour, min, sec] = Enum.map(String.split(time, ":"), &(String.to_integer &1))
      {:ok, name, %Ecto.DateTime{year: year, month: month, day: day, hour: hour, min: min, sec: sec}}
    rescue
      _ -> {:error, name, "Invalid date format"}
    end
  end

  def validate_type(:datetime, name, value) do
    {:error, name, "This needs to be a string"}
  end

  def validate_type(_, name, value), do: {:ok, name, value}


  @doc """
    Provides a hook you can override for custom validation on a specific 
    field. The type of the field may be acceptable, but you may want to 
    validate another property about the field, such as a number range, 
    or existence of a model, etc. 
  """
  def validate_field(_, key, val), do: {key, val}

  @doc """
    An overridable hook that runs after all the other validation
    that allows you to validate all fields together, ensuring that the
    combination of all fields is acceptable. If it is unacceptable
    then a {:bad_request, message} exception should be thrown. 
  """
  def validate_together(_, params, bundle), do: {params, bundle}


  @doc """
    Defines which fields are immune to validation
  """
  def ignore_fields(:create), do: [:id] ++ ignore_fields(nil)
  def ignore_fields(_), do: [:created, :modified]


  @doc """
    Adapt the erros that came out of the validation process to a helpful
    map that will be returned to the client 
  """
  def make_error_message(errors) do
    %{:errors => Enum.map(errors, fn {:error, name, value} -> {name, value} end) |> Enum.into(%{})}
  end


  defp params_to_check(verb, params, field_types) do
    included = Enum.filter(field_types, fn {name, _} -> not name in ignore_fields(verb) end) 
    Enum.map(included, fn {name, _type} -> {name, Dict.get(params, name)} end)
  end

  def validate({verb, conn, params, module, bundle}) do
    field_types = module.model.field_types
    check_params = params_to_check(verb, params, field_types)

    checked = check_params
      |> Enum.map(fn {key, val} -> {Keyword.fetch!(field_types, key), key, val} end)
      |> Enum.map(fn {field_type, key, val} -> validate_type(field_type, key, val) end)

    errors = Enum.filter(checked, fn {status, _, _} -> status == :error end)
    if length(errors) > 0, do: throw {:bad_request,  make_error_message(errors)}

    checked = checked
      |> Enum.map(fn {_, key, val} -> validate_field(verb, key, val) end)

    params = Enum.into(checked, params)
    {params, bundle} = validate_together(verb, params, bundle)
    {verb, conn, params, module, bundle}
  end



  @doc """
  
    Adds the handle/1 method for each REST verb
    by default a handle method for each verb is added, 
    but this is configurable via the options

    ## options
      :only list of verbs that will be validated
      :except list of verbs that will not be validated


  """
  defmacro __using__(options) do
    only = Keyword.get(options, :only, @verbs)
    except = Keyword.get(options, :except, [])
    only = (only -- except) 
    quote [unquote: false, bind_quoted: [only: only]] do

      for verb <- only do
        def handle({unquote(verb), conn, params, module, bundle}) do 
          Finch.Middleware.ModelValidator.validate({unquote(verb), conn, params, module, bundle})
        end
      end

      def handle({verb, conn, params, module, bundle}), do: {verb, conn, params, module, bundle}
    
      defoverridable [
        handle: 1
      ]
    end
  end

  

end