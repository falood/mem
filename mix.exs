defmodule Mem.Mixfile do
  use Mix.Project

  def project do
    [ app: :mem,
      name: :Mem,
      version: "0.2.0",
      elixir: "~> 1.2 or ~> 1.3 or ~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: "KV cache with TTL, Replacement and Persistence support",
      source_url: "https://github.com/falood/mem",
      package: package(),
      test_coverage: [tool: ExCoveralls],
    ]
  end

  def application do
    [ applications: [:logger] ]
  end

  defp deps do
    [ {:benchfella,  "~> 0.3", only: :bench},
      {:excoveralls, "~> 0.5", only: :test}
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/mem"}
     }
  end
end
