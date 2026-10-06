defmodule Kkhay.Client do
  @moduledoc """
  Client struct and HTTP request handler for the K Khay Payment Gateway.
  """

  alias Kkhay.ApiError

  defstruct [
    :api_key,
    base_url: "https://api.kkhay.com",
    timeout: 30_000
  ]

  @type t :: %__MODULE__{
          api_key: String.t(),
          base_url: String.t(),
          timeout: pos_integer()
        }

  def new(api_key, opts \\ []) do
    clean_key = String.trim(to_string(api_key))

    if clean_key == "" do
      raise ArgumentError, "Kkhay.Client: api_key is required"
    end

    base_url = Keyword.get(opts, :base_url, "https://api.kkhay.com") |> String.trim_trailing("/")
    timeout = Keyword.get(opts, :timeout, 30_000)

    %__MODULE__{
      api_key: clean_key,
      base_url: base_url,
      timeout: timeout
    }
  end

  def get_url(%__MODULE__{base_url: base_url}, path) do
    clean_path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"

    if String.ends_with?(base_url, "/api") or String.contains?(base_url, "api.") do
      "#{base_url}#{clean_path}"
    else
      "#{base_url}/api#{clean_path}"
    end
  end

  def request(%__MODULE__{} = client, method, path, body \\ nil) do
    url = get_url(client, path) |> String.to_charlist()

    headers = [
      {~c"accept", ~c"application/json"},
      {~c"x-api-key", String.to_charlist(client.api_key)},
      {~c"user-agent", ~c"kkhay-elixir/1.0.0"}
    ]

    http_method = method |> to_string() |> String.downcase() |> String.to_atom()

    http_req =
      case {http_method, body} do
        {:post, data} when not is_nil(data) ->
          json_bytes = Jason.encode!(data)
          post_headers = [{~c"content-type", ~c"application/json"} | headers]
          {url, post_headers, ~c"application/json", json_bytes}

        _ ->
          {url, headers}
      end

    http_opts = [timeout: client.timeout, connect_timeout: 10_000]

    case :httpc.request(http_method, http_req, http_opts, body_format: :binary) do
      {:ok, {{_http_ver, status_code, _phrase}, _resp_headers, resp_body}} ->
        decoded =
          case Jason.decode(resp_body) do
            {:ok, json} -> json
            _ -> %{"raw" => resp_body}
          end

        if status_code >= 400 do
          msg = decoded["message"] || decoded["error"] || "HTTP #{status_code} Error"
          code = decoded["code"]
          {:error, %ApiError{status: status_code, message: msg, code: code, details: decoded["details"]}}
        else
          {:ok, decoded}
        end

      {:error, reason} ->
        {:error, %ApiError{status: 500, message: "Network error: #{inspect(reason)}"}}
    end
  end
end

