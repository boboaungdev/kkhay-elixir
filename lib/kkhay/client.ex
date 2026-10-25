defmodule Kkhay.Client do
  @moduledoc """
  Client struct and HTTP request dispatcher for the K Khay Non-Custodial Crypto Payment Gateway.
  Supports 190+ blockchain networks and 500+ cryptocurrencies.
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

  @doc """
  Constructs a new K Khay client struct.
  """
  @spec new(String.t(), keyword()) :: t()
  def new(api_key, opts \\ []) do
    clean_key = String.trim(to_string(api_key))

    if clean_key == "" do
      raise ArgumentError, "Kkhay.Client: api_key is required and cannot be empty."
    end

    base_url = Keyword.get(opts, :base_url, "https://api.kkhay.com") |> String.trim_trailing("/")
    timeout = Keyword.get(opts, :timeout, 30_000)

    %__MODULE__{
      api_key: clean_key,
      base_url: base_url,
      timeout: timeout
    }
  end

  @doc """
  Resolves API endpoint URLs across subdomains, main domains, and custom proxies.
  """
  @spec get_url(t(), String.t()) :: String.t()
  def get_url(%__MODULE__{base_url: base_url}, path) do
    clean_path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"

    if String.ends_with?(base_url, "/api") or String.contains?(base_url, "api.") do
      "#{base_url}#{clean_path}"
    else
      "#{base_url}/api#{clean_path}"
    end
  end

  @doc """
  Normalizes invoice parameters from idiomatic Elixir snake_case or camelCase into standard API format.
  """
  @spec normalize_params(map()) :: map()
  def normalize_params(params) when is_map(params) do
    raw_amount =
      Map.get(params, :amount) || Map.get(params, "amount") ||
        Map.get(params, :price_amount) || Map.get(params, :priceAmount) ||
        Map.get(params, "priceAmount") || Map.get(params, "price_amount")

    amount =
      case raw_amount do
        nil -> nil
        val when is_number(val) -> val
        val when is_binary(val) ->
          case Float.parse(val) do
            {num, _} -> num
            :error -> nil
          end
      end

    currency =
      Map.get(params, :currency) || Map.get(params, "currency") ||
        Map.get(params, :price_currency) || Map.get(params, :priceCurrency) ||
        Map.get(params, "priceCurrency") || Map.get(params, "price_currency") || "USD"

    network =
      Map.get(params, :pay_network) || Map.get(params, :payNetwork) ||
        Map.get(params, "payNetwork") || Map.get(params, "pay_network")

    token =
      Map.get(params, :pay_token) || Map.get(params, :payToken) ||
        Map.get(params, "payToken") || Map.get(params, "pay_token")

    settlement =
      Map.get(params, :settlement_asset) || Map.get(params, :settlementAsset) ||
        Map.get(params, "settlementAsset") || Map.get(params, "settlement_asset")

    type =
      Map.get(params, :type) || Map.get(params, "type") || "PAYMENT"

    order_id =
      Map.get(params, :order_id) || Map.get(params, :orderId) ||
        Map.get(params, "orderId") || Map.get(params, "order_id")

    title =
      Map.get(params, :title) || Map.get(params, "title")

    customer_name =
      Map.get(params, :customer_name) || Map.get(params, :customerName) ||
        Map.get(params, "customerName") || Map.get(params, "customer_name")

    customer_email =
      Map.get(params, :customer_email) || Map.get(params, :customerEmail) ||
        Map.get(params, "customerEmail") || Map.get(params, "customer_email")

    redirect_url =
      Map.get(params, :redirect_url) || Map.get(params, :redirectUrl) ||
        Map.get(params, "redirectUrl") || Map.get(params, "redirect_url")

    cancel_url =
      Map.get(params, :cancel_url) || Map.get(params, :cancelUrl) ||
        Map.get(params, "cancelUrl") || Map.get(params, "cancel_url")

    ipn_url =
      Map.get(params, :ipn_callback_url) || Map.get(params, :ipnCallbackUrl) ||
        Map.get(params, "ipnCallbackUrl") || Map.get(params, "ipn_callback_url")

    metadata =
      Map.get(params, :metadata) || Map.get(params, "metadata")

    base = %{
      "amount" => amount,
      "priceAmount" => amount,
      "currency" => to_string(currency),
      "priceCurrency" => to_string(currency),
      "type" => String.upcase(to_string(type))
    }

    base
    |> maybe_put("payNetwork", network && String.downcase(to_string(network)))
    |> maybe_put("payToken", token && String.upcase(to_string(token)))
    |> maybe_put("settlementAsset", settlement)
    |> maybe_put("orderId", order_id)
    |> maybe_put("title", title)
    |> maybe_put("customerName", customer_name)
    |> maybe_put("customerEmail", customer_email)
    |> maybe_put("redirectUrl", redirect_url)
    |> maybe_put("cancelUrl", cancel_url)
    |> maybe_put("ipnCallbackUrl", ipn_url)
    |> maybe_put("metadata", metadata)
  end

  @doc """
  Normalizes query parameters into string key-value pairs for URL encoding.
  """
  @spec normalize_query(map()) :: map()
  def normalize_query(query) when is_map(query) do
    Enum.reduce(query, %{}, fn {k, v}, acc ->
      if is_nil(v) do
        acc
      else
        key_str = to_string(k)
        val_str =
          cond do
            key_str in ["status", "type"] -> String.upcase(to_string(v))
            true -> to_string(v)
          end
        Map.put(acc, key_str, val_str)
      end
    end)
  end

  @doc """
  Dispatches an HTTP request to the K Khay Gateway.
  """
  def request(%__MODULE__{} = client, method, path, body \\ nil) do
    url = get_url(client, path) |> String.to_charlist()

    headers = [
      {~c"accept", ~c"application/json"},
      {~c"x-api-key", String.to_charlist(client.api_key)},
      {~c"user-agent", ~c"kkhay-elixir/1.0.4"}
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

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, val)
end
