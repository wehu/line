defmodule Line.Router do

  import Plug.Connection
  use Plug.Router

  require EEx

  plug :match
  plug :dispatch

  @port {:n, :l, {__MODULE__, :port}}

  get "/" do
    send_resp(conn, 200, index(:guest, :gproc.get_value(@port, :gproc.lookup_pid(@port))))
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
    :gproc.reg(@port, port)
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
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_transport_name, req, opts) do
    :gproc.reg(@subpub)
    {:ok, req, opts}
  end

  def websocket_handle({:text, msg}, req, state) do
    #{:reply, {:text, "That's what she said! #{msg}"}, req, state}
    :gproc.send(@subpub, {self, @subpub, msg})
    {:ok, req, state}
  end

  def websocket_info({:timeout, _ref, msg}, req, state) do
    {:reply, {:text, msg}, req, state}
  end

  def websocket_info(info, req, state) do
    case info do
       {_pid, @subpub, msg} ->
           {:reply, {:text, msg}, req, state}
       _ -> {:ok, req, state}
    end
  end

  def websocket_terminate(_reason, _req, _state) do
    :gproc.unreg(@subpub)
    :ok
  end

end
