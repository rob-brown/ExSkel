defmodule ExSkel.Mixfile do
  use Mix.Project

  def project do
    [app: :exskel,
     version: "0.0.1",
     elixir: "~> 1.0.0",
     deps: deps]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      { :skel, git: "git@github.com:ParaPhrase/skel.git" },
    ]
  end
end
