defmodule ApidocsGenerator.Mixfile do
  use Mix.Project

  def project do
    [app: :apidocs_generator,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:phoenix, "~> 1.2.0"},
      {:poison,  "~> 2.0" },
    ]
  end
end
