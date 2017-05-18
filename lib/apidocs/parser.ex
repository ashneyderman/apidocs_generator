defmodule Apidocs.Parser do

  def parse(""), do: %{}
  def parse(nil), do: %{}
  def parse(block), do: do_parse(%{}, {nil, []}, String.split(block, "\n"))

  def do_parse(block, {_current_param, []}, []), do: block
  def do_parse(block, {current_param, buffer}, []) do
    append(block, current_param, parse_api_doc_param(current_param, buffer))
  end
  def do_parse(block, {current_param, buffer}, [line | lines]) do
#    r = parse_line(current_param, String.trim(line))
#    IO.puts """
#    ----
#    line: '#{line}'
#       r: #{inspect r, pretty: true}
#
#    """
#    case r do
    case parse_line(current_param, String.trim(line)) do
      :skip          -> block |> do_parse({current_param, buffer}, lines)
      {nil, data}    -> block |> do_parse({current_param, buffer ++ [String.trim(data)]}, lines)
      {new_param, data} ->
        if current_param do
          block
          |> append(current_param, parse_api_doc_param(current_param, buffer))
          |> do_parse({new_param, [String.trim(data)]}, lines)
        else
          block
          |> do_parse({new_param, buffer ++ [String.trim(data)]}, lines)
        end
    end
  end

  defp parse_api_doc_param(:apiDescription, buffer), do: buffer |> Enum.map(&String.trim/1) |> Enum.join("\n") |> String.trim("\n") |> String.split("\n")
  defp parse_api_doc_param(_ctag, buffer), do: buffer |> Enum.map(&String.trim/1) |> Enum.join("\n") |> String.trim("\n")

  defp parse_line(nil, ""),                         do: :skip
  defp parse_line(nil, data),                       do: {:apiTitle, data}
  defp parse_line(:apiTitle, data),                 do: {:apiDescription, data}
  defp parse_line(_, "@api " <> data),              do: {:api, data}
  defp parse_line(_, "@apiDeprecated" <> data),     do: {:apiDeprecated, data}
  defp parse_line(_, "@apiDescription" <> data),    do: {:apiDescription, data}
  defp parse_line(_, "@apiError" <> data),          do: {:apiError, data}
  defp parse_line(_, "@apiErrorExample" <> data),   do: {:apiErrorExample, data}
  defp parse_line(_, "@apiExample" <> data),        do: {:apiExample, data}
  defp parse_line(_, "@apiGroup" <> data),          do: {:apiGroup, data}
  defp parse_line(_, "@apiHeader" <> data),         do: {:apiHeader, data}
  defp parse_line(_, "@apiHeaderExample" <> data),  do: {:apiHeaderExample, data}
  defp parse_line(_, "@apiIgnore" <> data),         do: {:apiIgnore, data}
  defp parse_line(_, "@apiName" <> data),           do: {:apiName, data}
  defp parse_line(_, "@apiParam" <> data),          do: {:apiParam, data}
  defp parse_line(_, "@apiParamExample" <> data),   do: {:apiParamExample, data}
  defp parse_line(_, "@apiPermission" <> data),     do: {:apiPermission, data}
  defp parse_line(_, "@apiSampleRequest" <> data),  do: {:apiSampleRequest, data}
  defp parse_line(_, "@apiSuccess" <> data),        do: {:apiSuccess, data}
  defp parse_line(_, "@apiSuccessExample" <> data), do: {:apiSuccessExample, data}
  defp parse_line(_, "@apiUse" <> data),            do: {:apiUse, data}
  defp parse_line(_, "@apiVersion" <> data),        do: {:apiVersion, data}
  defp parse_line(_, data),                         do: {nil, data}

  @overrides [:apiTitle, :apiDescription, :apiVersion, :apiName, :apiGroup, :api]
  defp append(block, tag, data), do: append(block, tag, data, Enum.member?(@overrides, tag))

  defp append(block, tag, data, true), do: Map.put(block, tag, data)
  defp append(block, tag, data, false) do
    {_, result} = Map.get_and_update(
      block,
      tag,
      fn(nil) -> {nil, [data]}
        (current) -> {current, current ++ [data]}
      end)
    result
  end

end