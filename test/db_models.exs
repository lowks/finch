
defmodule Models.Foo do
  use Ecto.Model

  schema "foos" do
    field :a_string
    field :a_number, :integer
    field :a_datetime, :datetime
  end

  use Finch.Model
end


