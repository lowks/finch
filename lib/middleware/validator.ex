defmodule Finch.Middleware.ModelValidator do
  @verbs [:create, :show, :index, :destroy, :update]


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

  def validate_type(:datetime, name, value), do: {:error, name, "This needs to be a string"}

  def validate_type(_, name, value), do: {:ok, name, value}

  ###
  # By default, all fields just work. override this for specific stuff tho
  def validate_field(_, key, val), do: {key, val}
  def validate_together(_, params, bundle), do: {params, bundle}


  def ignore_fields(:create), do: [:id] ++ ignore_fields(nil)
  def ignore_fields(_), do: [:created, :modified]


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