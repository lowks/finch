defmodule Fixture do
  alias Ecto.Adapters.Postgres
  import Finch.Test.TableFixtures

  def correct_params do
    [database: "finch_test",
     username: "postgres",
     password: "postgres",
     hostname: "localhost"]
  end

  def drop_database do
    :os.cmd 'psql -U postgres -c "DROP DATABASE IF EXISTS finch_test;"'
  end

  def create_database do
    :os.cmd 'psql -U postgres -c "CREATE DATABASE finch_test;"'
  end



  def load do
    IO.puts("Loading db ")
    :ok = Postgres.storage_down(correct_params)
    :ok = Postgres.storage_up(correct_params)
    drop_database
    IO.puts("Drop db")
    create_database
    IO.puts("Create db")
    Ecto.Migrator.down(Repo, 0, Finch.Test.TableFixtures)
    IO.puts("Migrate down")
    Ecto.Migrator.up(Repo, 0, Finch.Test.TableFixtures)
    IO.puts("Migrate up")

  end

end

