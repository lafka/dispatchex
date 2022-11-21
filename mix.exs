defmodule DispatchEx.MixProject do
  use Mix.Project

  def project do
    version = "0.1.3"

    [
      app: :dispatchex,
      version: version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers() ++ [:dispatch],
      name: "DispatchEx",
      description: description(),
      source_url: "https://github.com/lafka/dispatchex",
      package: package(),
      fetch: fetch(version),
      docs: docs(version)
    ]
  end

  def application, do: []

  defp deps,
    do: [
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]

  defp description() do
    """
    Pattern matchable protocols
    """
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "dispatchex",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["BSD-3-Clause"],
      links: %{"GitHub" => "https://github.com/lafka/dispatchex"}
    ]
  end

  defp fetch(version) do
    [scm: :git, url: "git://github.com/lafka/dispatchex.git", tag: "v#{version}"]
  end

  defp docs(version) do

    [
      extras: ["README.md", "LICENSE", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{version}"
    ]
  end
end
