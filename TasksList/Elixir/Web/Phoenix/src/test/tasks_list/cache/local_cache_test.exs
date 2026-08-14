defmodule TasksList.Cache.LocalCacheTest do
  use ExUnit.Case, async: true

  setup do
    TasksList.Cache.LocalCache.delete("test:key")
    :ok
  end

  test "set and get round trip" do
    :ok = TasksList.Cache.LocalCache.set("test:key", %{a: 1}, 60)
    assert {:ok, %{a: 1}} = TasksList.Cache.LocalCache.get("test:key")
  end

  test "get missing returns error" do
    assert TasksList.Cache.LocalCache.get("test:missing") == :error
  end

  test "delete removes key" do
    TasksList.Cache.LocalCache.set("test:key", "value", 60)
    :ok = TasksList.Cache.LocalCache.delete("test:key")
    assert TasksList.Cache.LocalCache.get("test:key") == :error
  end

  test "expired entry returns error" do
    TasksList.Cache.LocalCache.set("test:key", "value", 1)
    Process.sleep(1100)
    assert TasksList.Cache.LocalCache.get("test:key") == :error
  end
end
