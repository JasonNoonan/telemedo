defmodule Telemetrex.MixProject do
  use Mix.Project

  @source_url "https://github.com/JasonNoonan/telemetrex"

  def project do
    [
      app: :telemetrex,
      version: "0.2.0",
      description: "Elixir-friendly wrappers over `:telemetry`.",
      source_url: @source_url,
      homepage_url: @source_url,
      package: [
        licenses: ["Apache-2.0"],
        links: %{"GitHub" => @source_url}
      ],
      docs: docs(),
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev]},
      {:ex_doc, "~> 0.20", only: :dev, runtime: false},
      {:telemetry, "~> 1.0", optional: true}
    ]
  end

  defp docs() do
    [
      main: "Telemetrex",
      extra_section: "GUIDES",
      extras: [
        "docs/testing.md"
      ]
    ]
  end
end
