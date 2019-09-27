# Это точка входа в приложение.
defmodule KVstore do
  use Application
  require Logger

  def start(_type, _args) do
    Logger.info("KVStore started...", [])
    port = Application.get_env(:kvstore, :port)
    children = [
      Plug.Adapters.Cowboy.child_spec(:http, Router, [], port: port),
      Storage
    ]
    Supervisor.start_link(children, [strategy: :one_for_one, name: KV.Supervisor])
  end
end
