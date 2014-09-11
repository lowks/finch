defmodule Finch do
	use Application

  def start(_type, _args) do
  	IO.puts("STARTING")
    Finch.Supervisor.start_link
  end

end
