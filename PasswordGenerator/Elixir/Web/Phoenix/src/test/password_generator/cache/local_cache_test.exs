defmodule PasswordGenerator.Cache.LocalCacheTest do
  use ExUnit.Case, async: true

  setup do
    PasswordGenerator.Cache.LocalCache.delete("test:key")
    :ok
  end

  test "set and get round trip" do
    :ok = PasswordGenerator.Cache.LocalCache.set("test:key", %{a: 1}, 60)
    assert {:ok, %{a: 1}} = PasswordGenerator.Cache.LocalCache.get("test:key")
  end

  test "get missing returns error" do
    assert PasswordGenerator.Cache.LocalCache.get("test:missing") == :error
  end

  test "delete removes key" do
    PasswordGenerator.Cache.LocalCache.set("test:key", "value", 60)
    :ok = PasswordGenerator.Cache.LocalCache.delete("test:key")
    assert PasswordGenerator.Cache.LocalCache.get("test:key") == :error
  end

  test "expired entry returns error" do
    PasswordGenerator.Cache.LocalCache.set("test:key", "value", 1)
    Process.sleep(1100)
    assert PasswordGenerator.Cache.LocalCache.get("test:key") == :error
  end
end
