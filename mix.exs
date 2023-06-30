defmodule Libmention.MixProject do
  use Mix.Project

  def project do
    [
      app: :libmention,
      version: "0.1.4",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: package(),
      name: "libmention",
      source_url: "https://github.com/silbermm/libmention",
      docs: docs(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :castore]
    ]
  end

  defp package() do
    [
      maintainers: ["Matt Silbernagel"],
      description: description(),
      links: %{
        :GitHub => "https://github.com/silbermm/libmention",
        :Webmentions => "https://www.w3.org/TR/webmention/"
      },
      licenses: ["Apache-License-2.0"],
      files: [
        "lib",
        "mix.exs",
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "libmention.png"
      ]
    ]
  end

  defp description do
    """
    A WebMention (https://www.w3.org/TR/webmention/) implementation for Elixir
    """
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.0"},
      {:telemetry, "~> 1.2"},
      {:req, "~> 0.3"},
      {:floki, "~> 0.34.3"},
      {:ex_doc, "~> 0.29", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0.2", only: [:test]},
      {:mix_test_watch, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      assets: "assets",
      api_reference: false,
      extra_section: "GUIDES",
      extras: [
        "guides/examples/sending/using_with_nimblepublisher.md",
        "guides/examples/sending/setting_up_persistance_with_ecto.md",
        "README.md": [filename: "readme", title: "README"],
        "CHANGELOG.md": [filename: "changelog", title: "Changelog"],
        LICENSE: [filename: "LICENSE", title: "License"]
      ],
      groups_for_extras: [
        "Sending Examples": Path.wildcard("guides/examples/sending/*.md")
      ],
      groups_for_modules: [
        Sending: [Libmention.Outgoing, Libmention.Outgoing.Proxy],
        Receiving: [],
        Behaviours: [Libmention.StorageApi]
      ],
      logo: "libmention_simple.png",
      authors: ["Matt Silbernagel"],
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@8.13.3/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({ startOnLoad: false });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition, function (svgSource, bindListeners) {
            graphEl.innerHTML = svgSource;
            bindListeners && bindListeners(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""
end
