defmodule Finch.Test.Foo do
  use Ecto.Model

  schema "foos" do
    field :title, :string
    field :text, :string
  end

  use Finch.Model
end

defmodule Finch.Test.Bar do
  use Ecto.Model

  schema "bars" do
    field :a_string, :string
    field :an_int, :integer
    field :a_bool, :boolean
    field :a_dt, :datetime

  end

  use Finch.Model
end