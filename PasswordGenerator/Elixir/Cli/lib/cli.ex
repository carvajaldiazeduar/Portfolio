defmodule PasswordGenerator.CLI do
  @moduledoc """
  Interactive password generator CLI (escript entry point).
  """

  alias PasswordGenerator.Generator

  def main(args) do
    if args == [] do
      menu()
    else
      case parse_args(args) do
        {:ok, opts} -> run(opts)
        {:error, msg} -> IO.puts("Error: #{msg}")
      end
    end
  end

  defp menu do
    IO.puts("=== Password Generator ===")

    length =
      case Integer.parse(IO.gets("Length (default 16): ") |> String.trim()) do
        {n, _} -> n
        :error -> 16
      end

    use_upper = yes?("Include uppercase? (Y/n): ")
    use_lower = yes?("Include lowercase? (Y/n): ")
    use_digits = yes?("Include digits? (Y/n): ")
    use_symbols = yes?("Include symbols? (Y/n): ")

    run(%{length: length, upper: use_upper, lower: use_lower, digits: use_digits, symbols: use_symbols})
  end

  defp yes?(prompt) do
    (IO.gets(prompt) |> String.trim() |> String.downcase()) != "n"
  end

  defp run(opts) do
    case Generator.generate(opts.length, opts.upper, opts.lower, opts.digits, opts.symbols) do
      {:ok, password} -> IO.puts("\nGenerated password: #{password}")
      {:error, msg} -> IO.puts("Error: #{msg}")
    end
  end

  defp parse_args(args), do: do_parse(args, %{length: 16, upper: true, lower: true, digits: true, symbols: true})

  defp do_parse(["-l", value | rest], opts) do
    case Integer.parse(value) do
      {n, _} -> do_parse(rest, %{opts | length: n})
      :error -> {:error, "Invalid length: #{value}"}
    end
  end

  defp do_parse(["--length", value | rest], opts), do: do_parse(["-l", value | rest], opts)
  defp do_parse(["--no-upper" | rest], opts), do: do_parse(rest, %{opts | upper: false})
  defp do_parse(["--no-lower" | rest], opts), do: do_parse(rest, %{opts | lower: false})
  defp do_parse(["--no-digits" | rest], opts), do: do_parse(rest, %{opts | digits: false})
  defp do_parse(["--no-symbols" | rest], opts), do: do_parse(rest, %{opts | symbols: false})
  defp do_parse([], opts), do: {:ok, opts}
  defp do_parse([unknown | _], _opts), do: {:error, "Unknown argument: #{unknown}"}
end