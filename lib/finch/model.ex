defmodule Finch.Model do

  defmacro __using__(_opts) do
    quote do
      use Ecto.Model
      def adapt(atom_keylist) do
        atom_keylist
      end

      def field_types do
        Enum.map(__MODULE__.__schema__(:field_names), fn name -> {name, __MODULE__.__schema__(:field_type, name)} end)
      end

      def allocate(params) do
        adapted = Map.to_list(params) |> adapt
        struct(__MODULE__, adapted)
      end

      def has_user? do
        :user in __MODULE__.__schema__(:associations)
      end

    end
  end
end