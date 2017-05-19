defmodule ApidocsParserTest do
  use ExUnit.Case
  require Logger
  doctest Apidocs.Parser

#  defp parse_line(nil, ""),                         do: :skip
#  defp parse_line(nil, data),                       do: {:apiTitle, data}
#  defp parse_line(:apiTitle, data),                 do: {:apiDescription, data}
#  defp parse_line(_, "@api " <> data),              do: {:api, data}
#  defp parse_line(_, "@apiDeprecated" <> data),     do: {:apiDeprecated, data}
#  defp parse_line(_, "@apiDescription" <> data),    do: {:apiDescription, data}
#  defp parse_line(_, "@apiError" <> data),          do: {:apiError, data}
#  defp parse_line(_, "@apiErrorExample" <> data),   do: {:apiErrorExample, data}
#  defp parse_line(_, "@apiExample" <> data),        do: {:apiExample, data}
#  defp parse_line(_, "@apiGroup" <> data),          do: {:apiGroup, data}
#  defp parse_line(_, "@apiHeader" <> data),         do: {:apiHeader, data}
#  defp parse_line(_, "@apiHeaderExample" <> data),  do: {:apiHeaderExample, data}
#  defp parse_line(_, "@apiIgnore" <> data),         do: {:apiIgnore, data}
#  defp parse_line(_, "@apiName" <> data),           do: {:apiName, data}
#  defp parse_line(_, "@apiParam" <> data),          do: {:apiParam, data}
#  defp parse_line(_, "@apiParamExample" <> data),   do: {:apiParamExample, data}
#  defp parse_line(_, "@apiPermission" <> data),     do: {:apiPermission, data}
#  defp parse_line(_, "@apiSampleRequest" <> data),  do: {:apiSampleRequest, data}
#  defp parse_line(_, "@apiSuccess" <> data),        do: {:apiSuccess, data}
#  defp parse_line(_, "@apiSuccessExample" <> data), do: {:apiSuccessExample, data}
#  defp parse_line(_, "@apiUse" <> data),            do: {:apiUse, data}
#  defp parse_line(_, "@apiVersion" <> data),        do: {:apiVersion, data}

  test "basic example" do
    parsed = """
             Test title

             This is a multi paragraph description. This is paragraph 1.

             This is a multi paragraph description. This is paragraph 2

             This is a multi paragraph description. This is paragraph 3

             @apiVersion 2.1.0
             @api test
             """
             |> Apidocs.Parser.parse

    assert "Test title" == parsed[:apiTitle]
    assert "test" == parsed[:api]
    assert "2.1.0" == parsed[:apiVersion]
    assert ["This is a multi paragraph description. This is paragraph 1.",
            "", "This is a multi paragraph description. This is paragraph 2",
            "", "This is a multi paragraph description. This is paragraph 3"] == parsed[:apiDescription]
  end

  test "multiple parameters" do
    parsed = """
             Test title

             @apiParam {Integer} id User ID
             @apiParam {String}  name User name
             """
             |> Apidocs.Parser.parse

    assert true == Enum.member?(parsed[:apiParam], "{Integer} id User ID")
    assert true == Enum.member?(parsed[:apiParam], "{String}  name User name")
  end

  test "description overwrite" do
    parsed = """
             Test title

             Test description
             @apiDescription Overwrite description
             Several lines
             """
             |> Apidocs.Parser.parse

    assert ["Overwrite description", "Several lines"] = parsed[:apiDescription]
  end

  test "params right after title" do
    parsed = """
             Test title
             @apiParam {Integer} id User ID
             """
             |> Apidocs.Parser.parse

    assert "Test title" == parsed[:apiTitle]
    assert true == Enum.member?(parsed[:apiParam], "{Integer} id User ID")
  end

end
