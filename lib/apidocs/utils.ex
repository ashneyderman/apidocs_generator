defmodule Apidocs.Utils do

  def apidocs_config,
    do: Mix.Project.config |> Keyword.get(:docs, []) |> Keyword.get(:formatter_opts, []) |> Keyword.get(:apidocs, [])

  def docsroot,
    do: apidocs_config() |> Keyword.get(:docsroot, "apidocs")

  def docsoutput,
    do: apidocs_config() |> Keyword.get(:docsoutput, "_build/apidocs")

  def snippetsoutput,
    do: apidocs_config() |> Keyword.get(:snippetsoutput, "_build/snippets")

  def apidocs_json do
    apidocs_json_path = Path.absname("apidoc.json", docsroot())
    if File.exists?(apidocs_json_path) do
      Poison.decode!(File.read!(apidocs_json_path))
    else
      %{
        "name"        => Mix.Project.config |> Keyword.get(:app, "Unknown Name"),
        "title"       => Mix.Project.config |> Keyword.get(:app, "Unknown Title"),
        "description" => Mix.Project.config |> Keyword.get(:app, "Unknown Description"),
        "version"     => Mix.Project.config |> Keyword.get(:version, "0.0.0"),
        "url"         => "http://localhost"
      }
    end
  end

  def copy(from, to) do
    if File.exists?(from) do
      File.cp_r from, to
    else
      Mix.shell.info [:green, "directory #{Path.absname(from)} does not exist"]
    end
  end

end