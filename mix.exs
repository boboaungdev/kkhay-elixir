defmodule Kkhay.MixProject do
  use Mix.Project

  def project do
    [
      app: :kkhay,
      version: "1.0.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: "Official Elixir and Phoenix SDK for K Khay Sovereign Crypto Payment Gateway",
      package: package(),
      deps: deps(),
      source_url: "https://github.com/boboaungdev/kkhay-elixir",
      homepage_url: "https://kkhay.com"
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.4"},
      {:req, "~> 0.5.0", optional: true},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "kkhay",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/boboaungdev/kkhay-elixir",
        "Website" => "https://kkhay.com"
      }
    ]
  end
end

