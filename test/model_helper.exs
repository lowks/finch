defmodule Finch.Test.Foo do
  use Finch.Model

  schema "foos" do
    field :title, :string
    field :text, :string
  end

end

defmodule Finch.Test.Bar do
  use Finch.Model

  schema "bars" do
    field :a_string, :string
    field :an_int, :integer
    field :a_bool, :boolean
    field :a_dt, :datetime
  end

end


defmodule Finch.Test.FooComment do
  use Finch.Model

  schema "foo_comments" do
    field :title, :string
    belongs_to :foo, Finch.Test.Foo
  end

end