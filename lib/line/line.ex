defmodule Line.Router do

  import Plug.Connection
  use Plug.Router

  require EEx

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, index(:guest, 4000))
  end

  match _ do
    send_resp(conn, 404, "oops")
  end

  def start_link do
    port = case System.argv do
      [p] -> binary_to_integer(p, 10)
      _ -> 4000
    end
    :application.start(:gproc)
    dispatch = [{ :_, [{"/ws", Line.WebSocketHandler, [] },
                       {:_, Plug.Adapters.Cowboy.Handler, { __MODULE__, [] } } ] }]
    IO.puts "Running Line with Cowboy on http://localhost:#{port}"
    Plug.Adapters.Cowboy.http __MODULE__, [], port: port, dispatch: dispatch
  end 

  EEx.function_from_file :def, :index, "templates/index.eex", [:user, :port]

end

defmodule Line.WebSocketHandler do
  @behaviour :cowboy_websocket_handler

  @subpub {:p, :l, {:subpub, :websocket}}

  def init({:tcp, :http}, _req, _opts) do
IO.puts "connect ws"
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_transport_name, req, _opts) do
IO.puts "connect ws"
    :gproc.reg(@subpub)
    {:ok, req, :undefined_state}
  end

  def websocket_handle({:text, msg}, req, state) do
IO.puts "handle ws"
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
    :gproc.unreg(@subpub)
    :ok
  end

end
