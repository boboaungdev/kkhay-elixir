defmodule KkhayTest do
  use ExUnit.Case

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
  end

  test "webhook signature verification" do
    secret = "whsec_test_secret_123"
    payload = Jason.encode!(%{
      "event" => "payment.finished",
      "invoice_id" => "inv_123",
      "pay_amount" => "50.00",
      "pay_token" => "USDT"
    })

    signature =
      :crypto.mac(:hmac, :sha256, secret, payload)
      |> Base.encode16(case: :lower)

    # Valid
    assert Webhook.verify_signature(payload, signature, secret) == true

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
      "event" => "payment.finished",
      "invoice_id" => "inv_123"
    })

    signature =
      :crypto.mac(:hmac, :sha256, secret, payload)
      |> Base.encode16(case: :lower)

    {:ok, event} = Webhook.parse_event(payload, signature, secret)
    assert event["event"] == "payment.finished"
    assert event["invoice_id"] == "inv_123"

    {:error, %Kkhay.SignatureError{}} = Webhook.parse_event(payload, "invalid_sig", secret)
  end
end

