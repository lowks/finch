defmodule Finch.Test.TableFixtures do
  use Ecto.Migration

  def up do
    ["CREATE TABLE IF NOT EXISTS
        foos(
          id serial primary key,
          a_string varchar(32), 
          a_number integer, 
          a_datetime timestamp DEFAULT NOW(),
        )"
    ]
  end

  def down do
    ["DROP TABLE IF EXISTS foos"]
  end
end
