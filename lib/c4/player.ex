defmodule C4.Player do
  defstruct [:id, :name]

  alias C4.Player

  @type id :: String.t()
  @type t :: %Player{id: id(), name: String.t()}

  @spec new(id(), String.t()) :: t()
  def new(id, name), do: %Player{id: id, name: name}
end
