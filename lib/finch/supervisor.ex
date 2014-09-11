defmodule Finch.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    children = [
      worker(Repo, []), 
    ]
    supervise(children, strategy: :one_for_all)
  end

end