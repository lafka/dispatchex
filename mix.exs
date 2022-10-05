defmodule DispatchEx.MixProject do
  use Mix.Project

  def project do
    [
      app: :dispatchex,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers() ++ [:dispatch]
    ]
  end

  def application, do:  [ ]

  defp deps, do:  [ ]
end
