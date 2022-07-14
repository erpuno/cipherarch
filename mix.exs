defmodule CIPHER.Mixfile do
  use Mix.Project

  def project do
    [
      app: :cipherarch,
      version: "0.7.14",
      description: "CIPHER X.509 Signed Document Archive",
      package: package(),
      deps: deps()
    ]
  end

  def application do
    [mod: {CIPHER, []}, applications: [:logger, :n2o]]
  end

  def package do
    [
      files: ~w(libmix.exs),
      licenses: ["ISC"],
      maintainers: ["Namdak Tonpa"],
      name: :cipherarch,
      links: %{"GitHub" => "https://github.com/erpuno/cipherarch"}
    ]
  end

  def deps do
    [
      {:ex_doc, "~> 0.11", only: :dev},
      {:jsone, "~> 1.5.1"},
      {:n2o, "~> 8.12.1"}
    ]
  end
end
