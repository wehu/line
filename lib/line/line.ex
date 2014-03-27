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
    port = case System.argv do
      [p] -> binary_to_integer(p, 10)
      _ -> 4000
    end
    dispatch = [{ :_, [{"/ws", Line.WebSocketHandler, [] },
                       {:_, Plug.Adapters.Cowboy.Handler, { __MODULE__, [] } } ] }]
    IO.puts "Running Line with Cowboy on http://localhost:#{port}"
    Plug.Adapters.Cowboy.http __MODULE__, [], port: port, dispatch: dispatch
  end 

  EEx.function_from_file :def, :index, "templates/index.eex", [:user]

end

defmodule Line.WebSocketHandler do
  @behaviour :cowboy_websocket_handler

  def init({:tcp, :http}, _req, _opts) do
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_transport_name, req, _opts) do
    :erlang.start_timer(1000, self, "Hello!")
    {:ok, req, :undefined_state}
  end

  def websocket_handle({:text, msg}, req, state) do
    {:reply, {:text, "That's what she said! #{msg}"}, req, state}
  end

  def websocket_info({:timeout, _ref, msg}, req, state) do
    :erlang.start_timer(1000, self, "How' you doin'?")
    {:reply, {:text, msg}, req, state}
  end

  def websocket_info(_info, req, state) do
    {:ok, req, state}
  end

  def websocket_terminate(_reason, _req, _state) do
    :ok
  end

end
