defmodule Mem.Mixfile do
  use Mix.Project

  def project do
    [ app: :mem,
      name: :Mem,
      version: "0.3.1-dev",
      elixir: "~> 1.2 or ~> 1.3 or ~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: "KV cache with TTL, Replacement and Persistence support",
      source_url: "https://github.com/falood/mem",
      package: package(),
      test_coverage: [tool: ExCoveralls],
      docs: [
        extras: ["README.md"],
        main: "readme",
      ]
    ]
  end

  def application do
    [ applications: [:logger] ]
  end

  defp deps do
    [ { :excoveralls, "~> 0.5",  only: :test },
      { :ex_doc,      "~> 0.14", only: :docs },
      { :benchfella,  "~> 0.3",  only: :bench },
    ]
  end

  defp package do
    %{ maintainers: ["Xiangrong Hao"],
       licenses: ["WTFPL"],
       links: %{"Github" => "https://github.com/falood/mem"}
     }
  end
end
