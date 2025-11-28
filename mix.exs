defmodule Supermarket.MixProject do
  use Mix.Project

  def project do
    [
      app: :supermarket,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ecto_sql, :postgrex],
      mod: {Supermarket.Application, []}
    ]
  end

  defp deps do
    [
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:plug_crypto, "~> 2.0"}
    ]
  end
end
