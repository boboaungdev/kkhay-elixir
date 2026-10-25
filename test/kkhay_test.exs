defmodule KkhayTest do
  use ExUnit.Case

  alias Kkhay.Client
  alias Kkhay.Webhook

  test "client initialization" do
    client = Kkhay.client("test_key")
    assert client.api_key == "test_key"
    assert client.base_url == "https://api.kkhay.com"
  end

  test "client initialization raises on empty key" do
    assert_raise ArgumentError, fn ->
      Kkhay.client("")
    end

    assert_raise ArgumentError, fn ->
      Kkhay.client("   ")
    end
  end

  test "get_url builds correct endpoints" do
    client = Kkhay.client("test_key")
    assert Client.get_url(client, "/v1/gateway/invoices") == "https://api.kkhay.com/v1/gateway/invoices"
    assert Client.get_url(client, "v1/gateway/invoices") == "https://api.kkhay.com/v1/gateway/invoices"

    local_client = Kkhay.client("test_key", base_url: "http://localhost:3000")
    assert Client.get_url(local_client, "/v1/gateway/invoices") == "http://localhost:3000/api/v1/gateway/invoices"
  end

  test "param normalization maps snake_case and camelCase" do
    params = %{
      amount: 49.99,
      pay_network: "bsc",
      pay_token: "usdt",
      order_id: "ORD-99",
      title: "Annual Pro Plan"
    }

    normalized = Client.normalize_params(params)
    assert normalized["amount"] == 49.99
    assert normalized["priceAmount"] == 49.99
    assert normalized["currency"] == "USD"
    assert normalized["payNetwork"] == "bsc"
    assert normalized["payToken"] == "USDT"
    assert normalized["orderId"] == "ORD-99"
    assert normalized["title"] == "Annual Pro Plan"
    assert normalized["type"] == "PAYMENT"
  end

  test "query normalization formats status and types" do
    query = %{status: "paid", limit: 10, page: 1}
    normalized = Client.normalize_query(query)
    assert normalized["status"] == "PAID"
    assert normalized["limit"] == "10"
    assert normalized["page"] == "1"
  end

  test "webhook signature verification" do
    secret = "whsec_test_secret_123"
    payload = Jason.encode!(%{
      "event" => "payment.paid",
      "invoice_id" => "01940000-0000-7000-8000-000000000001",
      "gateway_id" => "gw_123",
      "pay_amount" => "50.00",
      "pay_token" => "USDT",
      "status" => "PAID"
    })

    signature =
      :crypto.mac(:hmac, :sha256, secret, payload)
      |> Base.encode16(case: :lower)

    # Valid
    assert Webhook.verify_signature(payload, signature, secret) == true
    assert Kkhay.verify_webhook_signature(payload, signature, secret) == true

    # Tampered
    assert Webhook.verify_signature(payload <> "tampered", signature, secret) == false

    # Wrong secret
    assert Webhook.verify_signature(payload, signature, "wrong_secret") == false

    # Empty signature
    assert Webhook.verify_signature(payload, "", secret) == false

    # Nil signature
    assert Webhook.verify_signature(payload, nil, secret) == false
  end

  test "webhook parse event" do
    secret = "whsec_test_secret_123"
    payload = Jason.encode!(%{
      "event" => "payment.paid",
      "invoice_id" => "inv_123",
      "gateway_id" => "gw_xyz",
      "order_id" => "ORD-77",
      "status" => "PAID"
    })

    signature =
      :crypto.mac(:hmac, :sha256, secret, payload)
      |> Base.encode16(case: :lower)

    {:ok, event} = Webhook.parse_event(payload, signature, secret)
    assert event["event"] == "payment.paid"
    assert event["invoice_id"] == "inv_123"
    assert event["gateway_id"] == "gw_xyz"
    assert event["order_id"] == "ORD-77"
    assert event["status"] == "PAID"

    # Also test delegated function
    {:ok, delegated_event} = Kkhay.parse_webhook_event(payload, signature, secret)
    assert delegated_event["event"] == "payment.paid"
  end

  test "webhook parse event returns error on bad signature" do
    secret = "whsec_test_secret_123"
    payload = "{\"event\":\"payment.paid\"}"

    assert {:error, %Kkhay.SignatureError{}} =
             Webhook.parse_event(payload, "invalid_sig", secret)
  end
end
