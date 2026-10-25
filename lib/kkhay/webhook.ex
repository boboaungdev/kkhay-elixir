defmodule Kkhay.Webhook do
  @moduledoc """
  Cryptographic HMAC-SHA256 signature verification for K Khay IPN webhooks.
  """

  alias Kkhay.SignatureError

  @doc """
  Verifies the cryptographic HMAC-SHA256 signature sent with incoming K Khay IPN webhooks.

  Returns `true` if the signature is authentic and untampered.
  """
  @spec verify_signature(binary(), binary() | nil, binary()) :: boolean()
  def verify_signature(_payload, nil, _webhook_secret), do: false
  def verify_signature(_payload, "", _webhook_secret), do: false
  def verify_signature(_payload, _sig, ""), do: false

  def verify_signature(payload, signature, webhook_secret)
      when is_binary(payload) and is_binary(signature) and is_binary(webhook_secret) do
    secret = String.trim(webhook_secret)
    expected_hex =
      :crypto.mac(:hmac, :sha256, secret, payload)
      |> Base.encode16(case: :lower)

    secure_compare(expected_hex, String.trim(signature) |> String.downcase())
  rescue
    _ -> false
  end

  @doc """
  Validates and parses an incoming raw webhook body.
  Returns `{:ok, event_map}` on success or `{:error, %SignatureError{}}` on invalid signature.
  """
  @spec parse_event(binary(), binary() | nil, binary()) :: {:ok, map()} | {:error, any()}
  def parse_event(raw_body, signature, webhook_secret) do
    if verify_signature(raw_body, signature, webhook_secret) do
      case Jason.decode(raw_body) do
        {:ok, map} -> {:ok, map}
        {:error, reason} -> {:error, reason}
      end
    else
      {:error, %SignatureError{}}
    end
  end

  defp secure_compare(a, b) when byte_size(a) == byte_size(b) do
    :crypto.hash(:sha256, a) == :crypto.hash(:sha256, b)
  end

  defp secure_compare(_, _), do: false
end
