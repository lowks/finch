defmodule Finch.Mixfile do
  use Mix.Project

  def project do
    [app: :finch,
     version: "0.0.1",
     elixir: "~> 1.0.0",
     deps: deps]
  end


  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [ {:phoenix, "0.4.1"},
      {:cowboy, "~> 1.0.0"},
      {:postgrex, "0.6.0"},
      {:ecto, "0.2.4"},
      {:jazz, github: "meh/jazz"}
    ]
  end
end
