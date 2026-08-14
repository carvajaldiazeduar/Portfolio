defmodule PasswordGenerator.GeneratorTest do
  use ExUnit.Case, async: true

  alias PasswordGenerator.Generator

  test "generates a password of requested length" do
    assert {:ok, pw} = Generator.generate(16, true, true, true, false)
    assert String.length(pw) == 16
  end

  test "includes chars from enabled categories" do
    assert {:ok, pw} = Generator.generate(8, true, true, true, false)
    assert pw =~ ~r/[a-z]/
    assert pw =~ ~r/[A-Z]/
    assert pw =~ ~r/[0-9]/
  end

  test "symbols included when enabled" do
    assert {:ok, pw} = Generator.generate(8, true, true, true, true)
    assert pw =~ ~r/[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]/
  end

  test "rejects non-positive length" do
    assert {:error, "Password length must be at least 1"} = Generator.generate(0, true, true, true, false)
  end

  test "rejects when no category enabled" do
    assert {:error, "At least one character category must be enabled"} =
             Generator.generate(16, false, false, false, false)
  end

  test "rejects when length smaller than category count" do
    assert {:error, "Password length must be at least 4 when 4 categories are enabled"} =
             Generator.generate(3, true, true, true, true)
  end
end