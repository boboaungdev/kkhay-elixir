defmodule Kkhay.Webhook do
  @moduledoc """
  Cryptographic HMAC-SHA256 signature verification for K Khay IPN webhooks.
  """

  alias Kkhay.SignatureError

  @doc """
  Verifies the HMAC-SHA256 signature from the `x-kkhay-signature` header.
  """
  @spec verify_signature(binary(), binary() | nil, binary()) :: boolean()
  def verify_signature(_payload, nil, _ipn_secret), do: false
  def verify_signature(_payload, "", _ipn_secret), do: false
  def verify_signature(_payload, _sig, ""), do: false

  def verify_signature(payload, signature, ipn_secret)
      when is_binary(payload) and is_binary(signature) and is_binary(ipn_secret) do
    secret = String.trim(ipn_secret)
    expected_hex =
      :crypto.mac(:hmac, :sha256, secret, payload)
      |> Base.encode16(case: :lower)

    secure_compare(expected_hex, String.trim(signature) |> String.downcase())
  rescue
    _ -> false
  end

  @doc """
  Parses and validates an incoming raw webhook body.
  """
  @spec parse_event(binary(), binary() | nil, binary()) :: {:ok, map()} | {:error, any()}
  def parse_event(raw_body, signature, ipn_secret) do
    if verify_signature(raw_body, signature, ipn_secret) do
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

