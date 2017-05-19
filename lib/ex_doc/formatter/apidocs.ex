defmodule ExDoc.Formatter.APIDOCS do
  @moduledoc """
  Generate `apidoc` documentation for Elixir projects
  """

  import Apidocs.Utils

  @doc """
  Generate HTML documentation for the given modules
  """
  @spec run(list, ExDoc.Config.t) :: String.t
  def run(_project_nodes, config) when is_map(config) do
    prepare_docsoutput
    filter_func = apidocs_config |> Keyword.get(:filter, &always_include_filter/1)
    apidocs_config
    |> Keyword.get(:routers, [])
    |> Enum.flat_map(fn(route) -> (route.__routes__ |> Enum.filter(filter_func)) end)
    |> Enum.map(&find_docs/1)
    |> Enum.map(fn(rdoc) -> generate_apidocs(rdoc, apidocs_config) end)

    "#{Path.absname(docsoutput)}"
  end

  defp prepare_docsoutput do
    File.rm_rf!(docsoutput)
    :ok = Mix.Generator.create_directory(docsoutput)
    copy(docsroot, docsoutput)
  end

  defp always_include_filter(%Phoenix.Router.Route{}), do: true
  defp always_include_filter(_), do: false

#  {{:index, 2},
#   4,
#   :def,
#   [{:conn, [], nil}, {:params, [], nil}],
#   "  Display upload document form\n"},
  defp find_docs(route) do
    handler_func = route.opts
    Code.get_docs(route.plug, :docs)
    |> Enum.find(fn({{^handler_func, _}, _, :def, _params, false}) -> false
                   ({{^handler_func, _}, _, :def, _params, _docs}) -> true
                   (_) -> false
                 end)
    |> (fn({{_, _}, _, :def, _params, docs}) -> {route, docs}
          (_) -> {route, """
                         FIXME - no documentation

                         @apiDescription FIXME - no documentation
                         """}
        end).()
  end

#[{%Phoenix.Router.Route{assigns: %{}, helper: "fileupload", host: nil,
#   kind: :match, opts: :index, path: "/api/fileupload", pipe_through: [:api],
#   plug: Beginnings.FileuploadController, private: %{}, verb: :get},
#  "Display upload document form\n"},
# {%Phoenix.Router.Route{assigns: %{}, helper: "fileupload", host: nil,
#   kind: :match, opts: :upload, path: "/api/fileupload", pipe_through: [:api],
#   plug: Beginnings.FileuploadController, private: %{}, verb: :post},
#  "Upload document and display its content\n"}]

#/**
# * @api {post} /accounts/:id/contact contact us
# * @apiDescription FIXME (alex - 01/02/2015) add description
# * @apiGroup Accounts
# * @apiVersion 2.0.0
# * @apiName contact us
# * @apiParam {String} id Account uuid

  defp make_list(v) when is_list(v), do: List.zip([(for i <- 0..(Enum.count(v)-1), do: i),v])
  defp make_list(v), do: [{0,v}]

  defp do_multiline_possible([val], _prefix, _separator), do: val
  defp do_multiline_possible([val0|vals], prefix, separator), do: [val0 | Enum.map(vals, &( "#{prefix}#{&1}" )) ] |> Enum.join(separator)
  defp do_multiline_possible(val, _, _), do: val

  defp multiline_possible(list, prefix, separator) when is_list(list) do
    list |> Enum.map(fn({idx, val}) ->
       {idx, do_multiline_possible(String.split(val, "\n"), prefix, separator)}
    end)
  end

  defp replace_empty_desc(nil, title), do: title
  defp replace_empty_desc(desc, title) when is_list(desc) do
    if String.trim(Enum.join(desc, "")) == "",
    do: title,
    else: desc
  end

  defp all_example_requests(_config, %{opts: handler_func, plug: module}) do
    case File.ls(snippetsoutput) do
      {:ok, files} ->
        files
        |> Enum.filter(fn(path) -> String.starts_with?(Path.basename(path), "#{module}.#{handler_func}") end)
        |> Enum.filter(fn(path) -> String.ends_with?(Path.basename(path), ".request") end)
        |> Enum.map(&(File.read!(Path.join(snippetsoutput,&1))))
      {:error, reason} ->
        Mix.shell.error "Unable to list files in snippets output directory #{snippetsoutput} - #{inspect reason, pretty: true}. Make sure you ran the tests that generate the examples before you try to generate apidocs"
        []
    end
  end

  defp all_example_responses(_config, %{opts: handler_func, plug: module}) do
    case File.ls(snippetsoutput) do
      {:ok, files} ->
        files
        |> Enum.filter(fn(path) -> String.starts_with?(Path.basename(path), "#{module}.#{handler_func}") end)
        |> Enum.filter(fn(path) -> String.ends_with?(Path.basename(path), ".response") end)
        |> Enum.map(&(File.read!(Path.join(snippetsoutput,&1))))
      {:error, reason} ->
        Mix.shell.error "Unable to list files in snippets output directory #{snippetsoutput} - #{inspect reason, pretty: true}. Make sure you ran the tests that generate the examples before you try to generate apidocs"
        []
    end
  end

  def generate_apidocs({%{verb: verb,
                          path: path,
                          helper: section,
                          opts: handler_func}=route, doc}, config) do
    apidocs_json_config = apidocs_json
    parsed_block = Apidocs.Parser.parse(doc)

    # keep formatted template here. the one that is used in the code is devoid of spaces (all lines are joined).
    #    template = "
    #    <%= for {idx, line} <- data do %>
    #      <%= if tag_first_only && idx > 0 do %>
    #        <%= prefix %> <%= line %><%= separator %>
    #      <% else %>
    #        <%= prefix %><%= param %> <%= line %><%= separator %>
    #      <% end %>
    #    <% end %>"
    template  = "<%= for {idx, d} <- data do %><%= prefix %><%= if tag_first_only && idx > 0 do %><%= d %><%= separator %><% else %><%= param %> <%= d %><%= separator %><% end %><% end %>"
    prefix    = " * "
    separator = "\n"
    bindings  = [prefix: prefix, separator: separator, tag_first_only: false]

    apiTitle       = Map.get(parsed_block, :apiTitle, "FIXME")
    apiParamData   = Map.get(parsed_block, :apiParam, []) |> make_list |> multiline_possible(prefix, separator)
    apiData        = Map.get(parsed_block, :api, "{#{verb}} #{path} #{apiTitle}") |> make_list
    apiNameData    = Map.get(parsed_block, :apiName, handler_func) |> make_list
    apiGroupData   = Map.get(parsed_block, :apiGroup, section) |> make_list
    apiDescData    = Map.get(parsed_block, :apiDescription) |> replace_empty_desc(apiTitle) |> make_list
    apiVersionData = Map.get(parsed_block, :apiVersion, "#{apidocs_json_config["version"]}") |> make_list

    apiExampleData         = all_example_requests(config, route)  |> make_list |> multiline_possible(prefix, separator)
    apiExampleResponseData = all_example_responses(config, route) |> make_list |> multiline_possible(prefix, separator)

    apiParams  = EEx.eval_string(template, bindings |> Keyword.put(:param, "@apiParam")       |> Keyword.put(:data, apiParamData))
    apiGroup   = EEx.eval_string(template, bindings |> Keyword.put(:param, "@apiGroup")       |> Keyword.put(:data, apiGroupData))
    api        = EEx.eval_string(template, bindings |> Keyword.put(:param, "@api")            |> Keyword.put(:data, apiData))
    apiName    = EEx.eval_string(template, bindings |> Keyword.put(:param, "@apiName")        |> Keyword.put(:data, apiNameData))
    apiDesc    = EEx.eval_string(template, bindings |> Keyword.put(:param, "@apiDescription") |> Keyword.put(:tag_first_only, true) |> Keyword.put(:data, apiDescData))
    apiVersion = EEx.eval_string(template, bindings |> Keyword.put(:param, "@apiVersion")     |> Keyword.put(:data, apiVersionData))

    apiExamples         = EEx.eval_string(template, bindings |> Keyword.put(:param, "@apiExample") |> Keyword.put(:data, apiExampleData))
    apiExampleResponses = EEx.eval_string(template, bindings |> Keyword.put(:param, "@apiSuccessExample") |> Keyword.put(:data, apiExampleResponseData))

    File.write! Path.join(docsoutput, "#{section}.js"),"""
    /**
    #{apiGroup}\
    #{api}\
    #{apiDesc}\
    #{apiParams}\
    #{apiName}\
    #{apiVersion}\
    #{apiExamples}\
    #{apiExampleResponses}\
     */
    """, [:append]
  end

end
