defmodule Finch.Mixfile do
  use Mix.Project

  def project do
    [app: :finch,
     version: "0.0.3",
     elixir: "~> 1.0.0",
     package: [
        contributors: ["Chris Duranti"],
        licenses: ["MIT"],
        links: [github: "https://github.com/rozap/finch"]
     ],
     description: """
      Resource layer for Phoenix and Ecto projects for auto-generated RESTful CRUD APIs.
     """,
     deps: deps]
  end


  defp deps do
    [ {:phoenix, "0.4.1"},
      {:cowboy, "~> 1.0.0"},
      {:postgrex, "0.6.0"},
      {:ecto, "0.2.4"},
      {:jazz, github: "meh/jazz"}
    ]
  end
end
