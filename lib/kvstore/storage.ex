# Этот модуль должен реализовать механизмы CRUD для хранения данных. Если одного модуля будет мало, то допускается создание модулей с префиксом "Storage" в названии.
defmodule Storage do
  use GenServer
  require Logger
  require Process
  @interval 1000
  @dbFile 'db.dets'
  @dbOpts [{:file, @dbFile}, {:type, :set}]
  @table :storage
  @compile {:parse_transform, :ms_transform}

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(init_arg) do
    Process.send_after(__MODULE__, :start, 0)
    {:ok, init_arg}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(:start, state) do
    :dets.open_file(@table, @dbOpts)
    Process.send_after(__MODULE__, :clean, @interval)
    {:noreply, state}
  end

  def handle_info(:clean, state) do
    cleanup()
    Process.send_after(__MODULE__, :clean, @interval)
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_msg, state) do
    :dets.close(@table)
    {:noreply, state}
  end

  def lookup(key) do
    result = :dets.lookup(@table, key)
    case result do
      [entry|_] -> entry
      [] -> nil
      other -> other
    end
  end

  def create(key, value, ttl) do
    :dets.insert_new(@table, {key, value, ttl, Utils.timestamp() + ttl}) === true
  end

  def update(key, value, ttl) do
    case :dets.member(@table, key) do
      true -> :dets.insert(@table, {key, value, ttl, Utils.timestamp() + ttl}) === :ok
      _ -> false
    end
  end

  def delete(key) do
    case :dets.member(@table, key) do
      true -> :dets.delete(@table,key) === :ok
      _ -> false
    end
  end

  defp cleanup() do
    now = Utils.timestamp()
    ms = :ets.fun2ms(fn({_, _, _, valid_thru}) when valid_thru < now -> true end)
    num_deleted = :dets.select_delete(@table, ms)
    if num_deleted > 0 do
      Logger.info("#{num_deleted} keys expired and cleaned...")
    end
  end
end
