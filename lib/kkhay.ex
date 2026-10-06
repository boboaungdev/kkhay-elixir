defmodule Kkhay do
  @moduledoc """
  Official Elixir SDK for K Khay Sovereign Crypto Payment Gateway.
  """

  alias Kkhay.Client

  @doc """
  Constructs a new Kkhay client struct.
  """
  def client(api_key, opts \\ []) do
    Client.new(api_key, opts)
  end

  @doc """
  Creates a new crypto payment invoice.
  """
  def create_invoice(%Client{} = client, params) when is_map(params) do
    Client.request(client, :post, "/v1/merchant/invoices", params)
  end

  @doc """
  Retrieves an invoice and its blockchain payment transactions.
  """
  def get_invoice(%Client{} = client, invoice_id) when is_binary(invoice_id) do
    Client.request(client, :get, "/v1/merchant/invoices/#{URI.encode(invoice_id)}")
  end

  @doc """
  Lists merchant invoices with optional pagination and filters.
  """
  def list_invoices(%Client{} = client, query \\ %{}) when is_map(query) do
    query_string = URI.encode_query(query)
    path = if query_string == "", do: "/v1/merchant/invoices", else: "/v1/merchant/invoices?#{query_string}"
    Client.request(client, :get, path)
  end
end

