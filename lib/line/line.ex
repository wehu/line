defmodule Line.Router do

  import Plug.Connection
  use Plug.Router

  require EEx

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, index(System.get_env("USER")))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def start_link do
    IO.puts "Running MyPlug with Cowboy on http://localhost:4000"
    Plug.Adapters.Cowboy.http __MODULE__, []
  end 

  EEx.function_from_file :def, :index, "templates/index.eex", [:user]

end
