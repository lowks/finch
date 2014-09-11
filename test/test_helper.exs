Code.require_file "plug_helper.exs", __DIR__
Code.require_file "db_repo.exs", __DIR__
Code.require_file "db_models.exs", __DIR__
Code.require_file "table_fixtures.exs", __DIR__
Code.require_file "db_fixtures.exs", __DIR__
Fixture.load

ExUnit.start
