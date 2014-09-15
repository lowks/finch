defmodule Finch.Model do

  defmacro __using__(_opts) do
    quote do
      use Ecto.Model

      @doc """
        Hook that is overridable by the user to adapt the model's
        parameters to fit the model's fields. 
      """
      def adapt(atom_keylist), do: atom_keylist

      @doc """
        Returns a model struct with the parameters that were passed in 
        via a map. Runs the model's adapt method before creating the struct
      """
      def allocate(params) do
        adapted = Map.to_list(params) |> adapt
        struct(__MODULE__, adapted)
      end

      @doc """
        Returns true of the model is associated with a user model
      """
      def has_user? do
        :user in __MODULE__.__schema__(:associations)
      end

      @doc """
        Return a keyword list where the key is the model's field name
        and the value is the type of that field
      """
      def field_types do
        Enum.map(__MODULE__.__schema__(:field_names), 
          fn name -> 
            {name, __MODULE__.__schema__(:field_type, name)} 
          end)
      end


      defoverridable [
        adapt: 1,
        allocate: 1,
        has_user?: 0,
        field_types: 0
      ]
    end
  end
end