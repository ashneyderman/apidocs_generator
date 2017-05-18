defmodule Apidocs.SnippetsGenerator do
  import Apidocs.Utils
  require Logger

  def snippet(conn, opts) do
    format = opts |> Keyword.get(:format, :curl)
    snippet(conn, format, opts)
  end

  defp snippet(conn, :curl, opts) do
#    IO.puts "============================================"
#    IO.puts "snippet conn: #{inspect conn, pretty: true}"
#    IO.puts "snippet opts: #{inspect opts, pretty: true}"

    name              = opts |> Keyword.get(:name, "Example")
    :ok               = Mix.Generator.create_directory(snippetsoutput)

    controller        = Map.get(conn, :private, %{}) |> Map.get(:phoenix_controller)
    action            = Map.get(conn, :private, %{}) |> Map.get(:phoenix_action)

    snippet_req_path  = Path.absname("#{controller}.#{action}-#{name}.curl.request", snippetsoutput)
    snippet_resp_path = Path.absname("#{controller}.#{action}-#{name}.curl.response", snippetsoutput)
    request_snippet   = do_generate_request_snippet(conn, opts, apidocs_json)
    response_snippet  = do_generate_response_snippet(conn, opts, apidocs_json)

    write_snippet(snippet_req_path, request_snippet, opts)
    write_snippet(snippet_resp_path, response_snippet, opts)

    if request_snippet,  do: File.write!(snippet_req_path, request_snippet)
    if response_snippet, do: File.write!(snippet_resp_path, response_snippet)
  end

  defp write_snippet(_file, nil, _opts), do: :ok
  defp write_snippet(file, content, opts) do
    File.write!(file, content)
    if Keyword.get(opts, :log, false) do
      Logger.debug "\n#{content}"
    end
  end

  defp do_generate_request_headers(conn, _opts) do
    req_headers = conn.req_headers
    Logger.error "req_headers: #{inspect req_headers, pretty: true}"
    if req_headers do
      headers = req_headers
                |> Enum.map(fn({name, value}) ->
                              "  -H \"#{name}: #{value}\""
                            end)
                |> Enum.join(" \\\n")
      " \\\n#{headers}"
    else
      ""
    end
  end

  defp do_generate_query(_conn, opts) do
    query_params = opts |> Keyword.get(:qparams)
    if query_params do
      str = query_params |> Enum.map(fn({k,v}) -> "#{k}=#{v}" end) |> Enum.join("&")
      "?#{str}"
    else
      ""
    end
  end

  defp do_generate_request_body(_conn, opts),
    do: opts |> Keyword.get(:body) |> do_generate_request_body

  defp do_generate_request_body(nil), do: ""
  defp do_generate_request_body(body) when is_binary(body) do
    pretty_body = body |> Poison.decode! |> Poison.encode!(pretty: true)
    """
     \\
    --data-binary @-<<EOF
    #{pretty_body}
    EOF
    """
  end
  defp do_generate_request_body(body) when is_map(body) do
    do_generate_request_body(body |> Poison.encode!)
  end

  defp is_json_response(conn) do
    headers_map = conn.resp_headers |> Enum.into(HashDict.new)
    key = headers_map
          |> Dict.keys
          |> Enum.find(nil, &(String.downcase(&1) == "content-type"))

    if key do
      headers_map
      |> Dict.get(key, "")
      |> String.downcase
      |> String.starts_with?("application/json")
    else
      false
    end
  end

  defp do_generate_response_status_line(conn, _opts),
    do: "HTTP/1.1 #{conn.status} #{Plug.Conn.Status.reason_phrase(conn.status)}"

  defp do_generate_response_headers(conn, _opts) do
    if conn.resp_headers do
      headers = conn.resp_headers
                |> Enum.map(fn({name, value}) ->
                              "#{name}: #{value}"
                            end)
                |> Enum.join("\n")
      "\n#{headers}"
    else
      ""
    end
  end

  defp do_generate_response_body(conn, false), do:
    "\n\n#{conn.resp_body}"

  defp do_generate_response_body(conn, true) do
    try do
      body = Poison.decode!(conn.resp_body) |> Poison.encode!(pretty: true)
      "\n\n#{body}"
    rescue
      _ in [Poison.SyntaxError] ->
        "\n\n#{conn.resp_body}"
      end
  end

  defp do_generate_response_body(conn, _opts),
    do: do_generate_response_body(conn, is_json_response(conn))

#    resp_decoded = if is_json_response(resp_headers) do
#      d = try do
#        Poison.decode!(resp_body)
#      rescue
#        _ in [Poison.SyntaxError] ->
#          resp_body
#      end
#
#      Logger.debug """
#
#      >>>>>>>>>>>>>>>>>>
#
#       * HTTP/1.1 #{resp_status} OK
#       * #{resp_headers |> curl_resp_headers |> lprefix(" * ")}
#       *
#       * #{resp_body |> Poison.decode! |> Poison.encode!([pretty: true]) |> lprefix(" * ")}
#      >>>>>>>>>>>>>>>>>>
#      """
#      d
#    else
#      Logger.debug """
#      >>>>>>>>>>>>>>>>>>
#
#       * HTTP/1.1 #{resp_status} OK
#       * #{resp_headers |> curl_resp_headers |> lprefix(" * ")}
#       *
#       * #{resp_body |> lprefix(" * ")}
#      >>>>>>>>>>>>>>>>>>
#      """
#      resp_body
#    end

  defp do_generate_response_snippet(conn, opts, _apidocs_json) do
    name                 = opts |> Keyword.get(:name, "Example")
    response_status_line = do_generate_response_status_line(conn, opts)
    response_headers     = do_generate_response_headers(conn, opts)
    response_body        = do_generate_response_body(conn, opts)

    """
    {curl} #{name}:
    #{response_status_line}\
    #{response_headers}\
    #{response_body}
    """
  end

#    if params.payload != <<>> do
#      Logger.debug """
#
#        <<<<<<<<<<<<<<<<<<
#
#         * curl -k -v -X #{params.method} \\
#         *  #{params.req_headers |> curl_req_headers |> lprefix(" *  ")}
#         *  #{url} \\
#         *  --data-binary @-<<EOF
#         * #{payload |> Poison.decode! |> Poison.encode!([pretty: true]) |> lprefix(" * ")}
#         * EOF
#        <<<<<<<<<<<<<<<<<<
#        """
#    else
#      Logger.debug """
#
#        <<<<<<<<<<<<<<<<<<
#
#         * curl -k -v -X #{params.method} \\
#         *  #{params.req_headers |> curl_req_headers |> lprefix(" *  ")}
#         *  #{params.url}
#        <<<<<<<<<<<<<<<<<<
#        """
#    end

  defp do_generate_request_snippet(conn, opts, apidocs_json) do
    name     = opts |> Keyword.get(:name, "Example")
    method   = conn.method
    req_path = conn.request_path
    url      = apidocs_json["url"]
    headers  = do_generate_request_headers(conn, opts)
    query    = do_generate_query(conn, opts)
    body     = do_generate_request_body(conn, opts)

    """
    {curl} #{name}:
    curl -k -v -X #{method} #{url}#{req_path}#{query}\
    #{headers}\
    #{body}\
    """
  end

end