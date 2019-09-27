# Для веб сервера нужен маршрутизатор, место ему именно тут.
defmodule Router do
  use Plug.Router
  require Logger

  @headerKey "x-key"
  @headerValue "x-value"
  @headerTtl "x-ttl"

  plug(:match)
  plug(:dispatch)

  # Create
  post "/" do
    [key] = Plug.Conn.get_req_header(conn, @headerKey)
    [value] = Plug.Conn.get_req_header(conn, @headerValue)
    [ttl] = Plug.Conn.get_req_header(conn, @headerTtl)
    {status, body} = case Storage.create(key, value, String.to_integer(ttl)) do
      true -> {201, "Created"}
      false -> {400, "Already exists"}
    end
    Logger.info("POST <#{key}, #{value}, #{ttl}> / -> #{status} #{body}")
    send_resp(conn, status, body)
  end

  # Read
  get "/:key" do
    {status, body} = case Storage.lookup(key) do
      nil -> {404, "Not found"}
      {_, value, _, _} -> {200, value}
      {:error, _reason} -> {500, "Internal server error"}
    end
    Logger.info("GET /#{key} -> #{status} #{body}")
    send_resp(conn, status, body)
  end

  # Update
  put "/:key" do
    [value] = Plug.Conn.get_req_header(conn, @headerValue)
    [ttl] = Plug.Conn.get_req_header(conn, @headerTtl)
    {status, body} = case Storage.update(key, value, String.to_integer(ttl)) do
      true -> {200, "OK"}
      false -> {404, "Not found"}
    end
    Logger.info("PUT /#{key} <#{value}, #{ttl}> -> #{status} #{body}")
    send_resp(conn, status, body)
  end

  # Delete
  delete "/:key" do
    {status, body} = case Storage.delete(key) do
      true -> {200, "OK"}
      false -> {404, "Not found"}
    end
    Logger.info("DELETE /#{key} -> #{status} #{body}")
    send_resp(conn, status, body)
  end

  # Catch-up
  match _ do
    send_resp(conn, 404, "Not found")
  end
end

