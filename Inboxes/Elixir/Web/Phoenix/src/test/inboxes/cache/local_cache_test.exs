defmodule Inboxes.Cache.LocalCacheTest do
  use ExUnit.Case, async: true

  setup do
    Inboxes.Cache.LocalCache.delete("test:key")
    :ok
  end

  test "set and get round trip" do
    :ok = Inboxes.Cache.LocalCache.set("test:key", %{a: 1}, 60)
    assert {:ok, %{a: 1}} = Inboxes.Cache.LocalCache.get("test:key")
  end

  test "get missing returns error" do
    assert Inboxes.Cache.LocalCache.get("test:missing") == :error
  end

  test "delete removes key" do
    Inboxes.Cache.LocalCache.set("test:key", "value", 60)
    :ok = Inboxes.Cache.LocalCache.delete("test:key")
    assert Inboxes.Cache.LocalCache.get("test:key") == :error
  end

  test "expired entry returns error" do
    Inboxes.Cache.LocalCache.set("test:key", "value", 1)
    Process.sleep(1100)
    assert Inboxes.Cache.LocalCache.get("test:key") == :error
  end
end
