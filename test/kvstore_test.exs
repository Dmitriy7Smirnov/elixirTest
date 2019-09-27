# Тестируем как можно больше кейсов.

defmodule Storage.Test do
  use ExUnit.Case, async: false
  @tempKey "tempKey"
  @tempValue "tempValue"
  @tempValue2 "tempValue2"
  @tempTtl 1

  setup do
    Process.sleep(1000)
  end

  test "create a new key" do
    Storage.delete(@tempKey)
    result = Storage.create(@tempKey, @tempValue, @tempTtl)
    Storage.delete(@tempKey)
    assert result
  end

  test "create an existing key" do
    Storage.delete(@tempKey)
    Storage.create(@tempKey, @tempValue, @tempTtl)
    result = Storage.create(@tempKey, @tempValue, @tempTtl)
    Storage.delete(@tempKey)
    assert result === false
  end

  test "read key" do
    Storage.delete(@tempKey)
    Storage.create(@tempKey, @tempValue, @tempTtl)
    result = case Storage.lookup(@tempKey) do
      {_, _, _, _} -> true
      nil -> false
    end
    Storage.delete(@tempKey)
    assert result
  end

  test "read non-existing key" do
    Storage.delete(@tempKey)
    assert Storage.lookup(@tempKey) === nil
  end

  test "update an existing key" do
    Storage.delete(@tempKey)
    Storage.create(@tempKey, @tempValue, @tempTtl)
    result = Storage.update(@tempKey, @tempValue2, @tempTtl)
    Storage.delete(@tempKey)
    assert result
  end

  test "update non-existing key" do
    Storage.delete(@tempKey)
    result = Storage.update(@tempKey, @tempValue2, @tempTtl)
    assert result === false
  end

  test "delete an existing key" do
    Storage.delete(@tempKey)
    Storage.create(@tempKey, @tempValue, @tempTtl)
    assert Storage.delete(@tempKey)
  end

  test "delete non-existing key" do
    Storage.delete(@tempKey)
    assert Storage.delete(@tempKey) === false
  end

  test "cleanup expired keys" do
    Storage.delete(@tempKey)
    Storage.create(@tempKey, @tempValue, @tempTtl)
    Process.sleep(2000)
    result = case Storage.lookup(@tempKey) do
      {_, _, _, _} -> true
      nil -> false
    end
    Storage.delete(@tempKey)
    assert result === false
  end
end
