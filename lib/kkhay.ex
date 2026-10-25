defmodule Kkhay do
  @moduledoc """
  Official Elixir and Phoenix SDK for K Khay — The Non-Custodial Crypto Payment Gateway.
  Accept 500+ cryptocurrencies across 190+ blockchain networks with zero custody.
  """

  alias Kkhay.Client
  alias Kkhay.Webhook

  defdelegate verify_webhook_signature(payload, signature, secret), to: Webhook, as: :verify_signature
  defdelegate parse_webhook_event(raw_body, signature, secret), to: Webhook, as: :parse_event

  @doc """
  Constructs a new Kkhay client struct.

  ## Examples

      client = Kkhay.client(System.get_env("KKHAY_API_KEY"))
  """
  def client(api_key, opts \\ []) do
    Client.new(api_key, opts)
  end

  @doc """
  Creates a new non-custodial crypto payment invoice.
  Supports both Elixir snake_case and standard API camelCase map keys.

  ## Examples

      {:ok, response} =
        Kkhay.create_invoice(client, %{
          amount: 49.99,
          currency: "USD",
          pay_network: "bsc",
          pay_token: "USDT",
          order_id: "ORD-1234",
          title: "Pro Subscription"
        })

      invoice = response["invoice"]
      IO.puts("Checkout URL: \#{invoice["hostedUrl"]}")
  """
  def create_invoice(%Client{} = client, params) when is_map(params) do
    normalized = Client.normalize_params(params)
    Client.request(client, :post, "/v1/gateway/invoices", normalized)
  end

  @doc """
  Retrieves an invoice and its blockchain payment transactions.

  ## Examples

      {:ok, response} = Kkhay.get_invoice(client, "01940000-0000-7000-8000-000000000001")
      invoice = response["invoice"]
      payments = response["payments"]
  """
  def get_invoice(%Client{} = client, invoice_id) when is_binary(invoice_id) do
    clean_id = String.trim(invoice_id)
    if clean_id == "" do
      raise ArgumentError, "Kkhay.get_invoice: invoice_id is required"
    end
    Client.request(client, :get, "/v1/gateway/invoices/#{URI.encode(clean_id)}")
  end

  @doc """
  Lists gateway invoices with optional pagination and filters.

  ## Options
    * `:page` - Page number (default: 1)
    * `:limit` - Number of invoices per page (default: 20)
    * `:status` - Filter by status ("WAITING", "PAID", "EXPIRED", "CANCELED")
    * `:type` - Filter by type ("PAYMENT", "DONATION", "SUBSCRIPTION")
    * `:search` - Search by invoice ID, order ID, or customer

  ## Examples

      {:ok, response} = Kkhay.list_invoices(client, %{status: "PAID", limit: 10})
      items = response["items"]
  """
  def list_invoices(%Client{} = client, query \\ %{}) when is_map(query) do
    normalized = Client.normalize_query(query)
    query_string = URI.encode_query(normalized)
    path = if query_string == "", do: "/v1/gateway/invoices", else: "/v1/gateway/invoices?#{query_string}"
    Client.request(client, :get, path)
  end
end
