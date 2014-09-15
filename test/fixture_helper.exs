ExUnit.start


alias Ecto.Adapters.Postgres
alias Finch.Test.TestRepo

defmodule Finch.Test.TestRepo do
  use Ecto.Repo, adapter: Ecto.Adapters.Postgres

  def priv do
    "integration_test/pg/ecto/priv"
  end

  def conf do
    parse_url "ecto://postgres:postgres@localhost/finch_test"
  end


end




defmodule Finch.Test.Case do
  use ExUnit.CaseTemplate

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      require TestRepo

      import Ecto.Query
      alias Finch.Test.TestRepo
      alias Finch.Test.Foo

      setup do
        IO.puts("DOING SETUP")
        Finch.Test.Case.setup_tables
        :ok
      end

    end
  end

  def sql_run commands do
    Enum.each(commands, fn(sql) ->
      :io.format("running: ~n~p~n", [sql])
      result = Postgres.query(TestRepo, sql, [])
      if match?({ :error, _ }, result) do
        IO.puts("Test database setup SQL error'd: `#{sql}`")
        IO.inspect(result)
        System.halt(1)
      end
    end)
  end


  def setup_tables do
    drop_tables = [
      "DROP TABLE IF EXISTS foo_comments",
      "DROP TABLE IF EXISTS foos",
      "DROP TABLE IF EXISTS bars"
    ]

    create_tables = [
      "CREATE TABLE foos (id serial PRIMARY KEY, title varchar(100), text varchar(100))",
      "CREATE TABLE bars (
        id serial PRIMARY KEY, 
        a_string varchar(100), 
        an_int integer, 
        a_bool boolean, 
        a_dt timestamp DEFAULT NOW()
      )",
      "CREATE TABLE foo_comments (
        id serial PRIMARY KEY, 
        title varchar(100), 
        foo_id integer references foos(id)
      )",

    ]
    sql_run drop_tables
    sql_run create_tables
  end

end

Application.ensure_all_started(:logger)


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


{ :ok, _pid } = TestRepo.start_link

