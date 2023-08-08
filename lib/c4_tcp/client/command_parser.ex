defmodule C4Tcp.Client.CommandParser do
  @type command ::
          :new
          | :print
          | :help
          | :who
          | :quit
          | {:drop, non_neg_integer()}
          | {:join, String.t()}
          | {:msg, String.t()}
          | {:username, String.t()}

  @type error ::
          :invalid_drop_index
          | :invalid_command
          | :invalid_game_code
          | :username_invalid
          | :username_too_long
          | :username_too_short
          | :empty

  @spec parse(String.t()) :: {:ok, command()} | {:error, error()}
  def parse("new"), do: {:ok, :new}
  def parse("print"), do: {:ok, :print}
  def parse("help"), do: {:ok, :help}
  def parse("quit"), do: {:ok, :quit}

  def parse("msg " <> message) when message != "", do: {:ok, {:msg, message}}

  def parse("who"), do: {:ok, :who}

  @game_id_regex ~r/^([A-Z0-9])+$/
  def parse("join " <> code) when code != "" do
    code = String.upcase(code)

    if Regex.match?(@game_id_regex, code) do
      {:ok, {:join, code}}
    else
      {:error, :invalid_game_code}
    end
  end

  def parse("drop " <> index) when index != "" do
    case Integer.parse(index) do
      {int, _} when int in 1..7 -> {:ok, {:drop, int}}
      _ -> {:error, :invalid_drop_index}
    end
  end

  @maximum_username_length 20
  @username_regex ~r/^[\w\d]+[-\w\d]+[\w\d]+$/
  def parse("username " <> username) do
    username = String.trim(username)

    cond do
      String.length(username) > @maximum_username_length ->
        {:error, :username_too_long}

      username == "" ->
        {:error, :username_too_short}

      not Regex.match?(@username_regex, username) ->
        {:error, :username_invalid}

      true ->
        {:ok, {:username, username}}
    end
  end

  def parse(""), do: {:error, :empty}

  def parse(_), do: {:error, :invalid_command}
end
