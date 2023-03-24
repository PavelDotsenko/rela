defmodule Rela.MixProject do
  use Mix.Project

  def project do
    [
      app: :rela,
      version: "1.0.1",
      elixir: "~> 1.13",
      deps: deps(),
      start_permanent: Mix.env == :prod,
      description:
        "Mechanism for simplified creation of relationships in the database between entities",
      package: package(),
      elixirc_paths: ["lib"],
      name: "Rela",
      source_url: "https://github.com/PavelDotsenko/rela"
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
      {:ecto_sql, "~> 3.6"},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md", ".gitignore", ".formatter.exs"],
      maintainers: ["Pavel Dotsenko", "Danil Farfudinov"],
      licenses: ["Apache 2.0"],
      links: %{
        GitHub: "https://github.com/PavelDotsenko/rela",
        Issues: "https://github.com/PavelDotsenko/rela/issues"
      }
    ]
  end
end
