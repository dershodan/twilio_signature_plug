defmodule TwilioSignaturePlug.MixProject do
  use Mix.Project

  @maintainers ["Christoph Leitner"]
  @url "https://github.com/dershodan/twilio_signature_plug"

  def project do
    [
      app: :twilio_signature_plug,
      version: "0.1..11",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      package: package()
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
      {:plug_cowboy, "~> 2.0"},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp description() do
    """
    Validate Twilio Request Signatures on your Webhooks
    """
  end

  defp package() do
    [
      maintainers: @maintainers,
      licenses: ["MIT"],
      links: %{"GitHub" => @url}
    ]
  end
end
