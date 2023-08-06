defmodule C4.Generator do
  @chars "abcdefghijklmnopqrstuvwxyz"
  @uppercase_chars String.upcase(@chars)
  @digits "0123456789"
  @all_chars String.to_charlist(@chars <> @uppercase_chars <> @digits)
  @uppercase_digits String.to_charlist(@uppercase_chars <> @digits)

  def random_id(type \\ :alphanumeric, length)

  def random_id(:uppernumeric, length) do
    generate(@uppercase_digits, length)
  end

  def random_id(:alphanumeric, length) do
    generate(@all_chars, length)
  end

  defp generate(chars, length) do
    chars
    |> Enum.shuffle()
    |> Enum.take(length)
    |> to_string()
  end
end
