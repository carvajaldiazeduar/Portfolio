defmodule Contacts.Cache.LocalCacheTest do
  use ExUnit.Case, async: true

  setup do
    Contacts.Cache.LocalCache.delete("test:key")
    :ok
  end

  test "set and get round trip" do
    :ok = Contacts.Cache.LocalCache.set("test:key", %{a: 1}, 60)
    assert {:ok, %{a: 1}} = Contacts.Cache.LocalCache.get("test:key")
  end

  test "get missing returns error" do
    assert Contacts.Cache.LocalCache.get("test:missing") == :error
  end

  test "delete removes key" do
    Contacts.Cache.LocalCache.set("test:key", "value", 60)
    :ok = Contacts.Cache.LocalCache.delete("test:key")
    assert Contacts.Cache.LocalCache.get("test:key") == :error
  end

  test "expired entry returns error" do
    Contacts.Cache.LocalCache.set("test:key", "value", 1)
    Process.sleep(1100)
    assert Contacts.Cache.LocalCache.get("test:key") == :error
  end
end
