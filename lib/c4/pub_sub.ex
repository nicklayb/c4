defmodule C4.PubSub do
  @server C4.PubSub

  @spec server_name() :: atom()
  def server_name, do: @server

  defp topic({:game, game_id}), do: "game:#{game_id}"
  defp topic({:game, game_id, player_id}), do: "#{topic({:game, game_id})}:#{player_id}"
  defp topic({:player, player_id}), do: "player:#{player_id}"

  def broadcast(topic, message) do
    Phoenix.PubSub.broadcast(@server, topic(topic), message)
  end

  def subscribe(topic) do
    Phoenix.PubSub.subscribe(@server, topic(topic))
  end

  def unsubscribe(topic) do
    Phoenix.PubSub.unsubscribe(@server, topic(topic))
  end
end
