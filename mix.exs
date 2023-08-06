defmodule C4.MixProject do
  use Mix.Project

  def project do
    [
      app: :c4,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {C4.Application, []}
    ]
  end

  defp elixirc_paths(env) when env in ~w(dev test)a, do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix_pubsub, "~> 2.1"}
    ]
  end
end
