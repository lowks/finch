ExUnit.start


alias Ecto.Adapters.Postgres
alias Ecto.Integration.Postgres.TestRepo

defmodule Ecto.Integration.Postgres.TestRepo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

  def priv do
    "integration_test/pg/ecto/priv"
  end

  def conf do
    parse_url "ecto://postgres:postgres@localhost/finch_test"
  end

  # def log(action, fun) do
  #   IO.inspect action
  #   fun.()
  # end

  def query_apis do
    [Ecto.Integration.Postgres.CustomAPI, Ecto.Query.API]
  end
end

defmodule Finch.Test.Foo do
  use Ecto.Model

  schema "posts" do
    field :title, :string
    field :text, :string
  end
end


defmodule Finch.Test.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      import unquote(__MODULE__)
      require TestRepo

      import Ecto.Query
      alias Finch.Test.TestRepo
      alias Finch.Test.Foo
    end
  end

end

Application.ensure_all_started(:logger)


IO.puts("WHAT")

setup_cmds = [
  ~s(psql -U postgres -h localhost -c "DROP DATABASE IF EXISTS finch_test;"),
  ~s(psql -U postgres -h localhost -c "CREATE DATABASE finch_test;")
]

Enum.each(setup_cmds, fn(cmd) ->
  key = :ecto_setup_cmd_output
  :io.format("running cmd ~p~n", [cmd])
  Process.put(key, "")
  status = Mix.Shell.cmd(cmd, fn(data) ->
    current = Process.get(key)
    Process.put(key, current <> data)
  end)


  if status != 0 do
    IO.puts """
    Test setup command error'd:

        #{cmd}

    With:

        #{Process.get(key)}
    Please verify the user "postgres" exists and it has permissions
    to create databases. If not, you can create a new user with:

        createuser postgres --no-password -d
    """
    System.halt(1)
  end
end)

setup_database = [
  "CREATE TABLE foos (id serial PRIMARY KEY, title varchar(100), text varchar(100))"
]

{ :ok, _pid } = TestRepo.start_link

Enum.each(setup_database, fn(sql) ->
  result = Postgres.query(TestRepo, sql, [])
  if match?({ :error, _ }, result) do
    IO.puts("Test database setup SQL error'd: `#{sql}`")
    IO.inspect(result)
    System.halt(1)
  end
end)
