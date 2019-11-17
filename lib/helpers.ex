defmodule Kurenai.Helpers do
  def parse_quoted(rest) do
    parse_quoted(rest, [])
  end

  defp parse_quoted(binary, parsed) when binary == "" do
    parsed
  end

  defp parse_quoted(binary, parsed) do
    [word, left] =
      case String.starts_with?(binary, "\"") do
        true ->
          case String.split(binary, "\"", parts: 3) do
            [_, word] -> [word, ""]
            [_, word, left] -> [word, left]
          end

        false ->
          case String.split(binary, " ", parts: 2) do
            [word] -> [word, ""]
            [word, left] -> [word, left]
          end
      end

    parse_quoted(left, parsed ++ [word])
  end
end
