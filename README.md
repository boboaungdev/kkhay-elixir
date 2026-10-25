# K Khay Elixir SDK 💧

**Official Elixir and Phoenix SDK for K Khay — The Non-Custodial Crypto Payment Gateway**

[![Hex version](https://img.shields.io/hexpm/v/kkhay.svg?style=flat-square&color=10b981)](https://hex.pm/packages/kkhay)
[![CI](https://github.com/boboaungdev/kkhay-elixir/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/boboaungdev/kkhay-elixir/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Elixir](https://img.shields.io/badge/Elixir-%3E%3D1.14-4B275F.svg?style=flat-square)](https://elixir-lang.org/)

Accept non-custodial cryptocurrency payments across **190+ blockchain networks** and **500+ tokens** (EVM, Bitcoin, Solana, TON, Tron, and XRPL) with **zero custody** and automatic direct-to-wallet settlement in **Phoenix** web applications and distributed Elixir OTP nodes.

[Gateway Dashboard](https://gateway.kkhay.com) • [API Keys](https://gateway.kkhay.com/dashboard/keys) • [Website](https://kkhay.com)

---

## ⚡ Highlights

- 🛡️ **100% Non-Custodial**: Payments settle directly to your destination blockchain address in seconds. K Khay never holds your private keys or customer funds.
- 🌐 **190+ Networks Supported**:
  - **EVM Networks (180+ Chains)**: BNB Smart Chain (`bsc`), Polygon (`polygon`), Base (`base`), Arbitrum (`arbitrum`), Ethereum (`ethereum`), Optimism (`optimism`), Avalanche (`avalanche`).
  - **UTXO Chains**: Bitcoin (`bitcoin`), Dogecoin (`dogecoin`), Litecoin (`litecoin`), Bitcoin Cash (`bitcoincash`).
  - **High-Throughput Chains**: Solana (`solana`), TON (`ton`), Tron (`tron`), XRP Ledger (`ripple`).
- 🪙 **500+ Tokens**: Native coins and tokens (USDT, USDC, BTC, ETH, SOL, TON, BNB, DOGE, XRP, TRX, LTC, DAI, and more).
- 🔗 **Branded Hosted Checkouts**: Automatic payment links with dynamic QR codes, live blockchain polling, and wallet deep linking.
- 🔔 **HMAC-SHA256 Cryptographic Webhooks**: Timing-safe verification matching `x-kkhay-signature`.
- ⚡ **Zero Native Dependencies**: Uses Erlang's built-in `:httpc` and `:crypto` modules with JSON decoding.

---

## 📦 Installation

Add `kkhay` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kkhay, "~> 1.0.4"}
  ]
end
```

Then run:

```bash
mix deps.get
```

---

## 🚀 Quick Start

### 1. Initialize the Client

Generate your API key in the [K Khay Gateway Dashboard](https://gateway.kkhay.com/dashboard/keys).

```elixir
client = Kkhay.client(System.get_env("KKHAY_API_KEY"))
```

---

### 2. Create a Crypto Payment Invoice

Accept stablecoins, native coins, or let the customer choose their chain on checkout:

```elixir
# Example: USDT on BNB Smart Chain (BSC)
{:ok, response} =
  Kkhay.create_invoice(client, %{
    amount: 49.99,
    currency: "USD",
    pay_network: "bsc",       # "bsc" | "polygon" | "base" | "arbitrum" | "ethereum" | "solana" | "bitcoin" | "ton"
    pay_token: "USDT",        # "USDT" | "USDC" | "BTC" | "ETH" | "SOL" | "TON"
    order_id: "ORDER-7711",   # Your internal order ID
    title: "Pro Subscription",
    customer_email: "elixirdev@example.com",
    redirect_url: "https://myshop.com/success"
  })

invoice = response["invoice"]
IO.puts("Invoice ID: #{invoice["id"]}")
IO.puts("Gateway ID: #{invoice["gatewayId"]}")
IO.puts("Deposit Address: #{invoice["depositAddress"]}")
IO.puts("Checkout Hosted URL: #{invoice["hostedUrl"]}")

# Redirect customer to the hosted checkout:
# Phoenix.Controller.redirect(conn, external: invoice["hostedUrl"])
```

```elixir
# Example: Native Bitcoin or Solana
{:ok, btc_res} =
  Kkhay.create_invoice(client, %{
    amount: 120.00,
    currency: "USD",
    pay_network: "bitcoin",
    pay_token: "BTC",
    order_id: "ORDER-7712"
  })
```

---

### 3. Fetch & List Invoices

```elixir
# Retrieve a single invoice with blockchain transaction history
{:ok, res} = Kkhay.get_invoice(client, "01940000-0000-7000-8000-000000000001")
invoice = res["invoice"]
payments = res["payments"]

IO.puts("Status: #{invoice["status"]}") # WAITING | PAID | EXPIRED | CANCELED

# List invoices with pagination
{:ok, list} = Kkhay.list_invoices(client, %{status: "PAID", limit: 10})
IO.puts("Total Paid Invoices: #{list["totalCount"]}")
```

---

### 4. Verify Incoming Webhooks (Phoenix Controller)

When a customer pays and the blockchain confirms the transaction, K Khay sends a cryptographically signed `POST` webhook to your server:

```elixir
defmodule MyAppWeb.KkhayWebhookController do
  use MyAppWeb, :controller
  alias Kkhay.Webhook

  def handle(conn, _params) do
    {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
    signature = Plug.Conn.get_req_header(conn, "x-kkhay-signature") |> List.first()
    secret = System.get_env("KKHAY_WEBHOOK_SECRET")

    case Webhook.parse_event(raw_body, signature, secret) do
      {:ok, event} ->
        if event["event"] == "payment.paid" do
          # Fulfill customer order in database
          MyApp.Orders.complete_order(event["order_id"], event["tx_hash"])
        end

        json(conn, %{ok: true})

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid webhook signature"})
    end
  end
end
```

---

## 🌐 Supported Networks & Families

| Network Family | Popular Chains | Supported Tokens |
| :--- | :--- | :--- |
| **EVM (180+ Chains)** | Ethereum, BNB Smart Chain, Polygon, Arbitrum, Base, Optimism, Avalanche | USDT, USDC, ETH, BNB, POL, AVAX, DAI, ERC-20s |
| **UTXO** | Bitcoin, Dogecoin, Litecoin, Bitcoin Cash | BTC, DOGE, LTC, BCH |
| **Solana** | Solana Mainnet | SOL, USDT, USDC |
| **TON** | The Open Network | TON, USDT |
| **Tron (TVM)** | Tron Mainnet | TRX, USDT |
| **XRPL** | XRP Ledger | XRP |

---

## 📄 License

MIT © [K Khay](https://kkhay.com)
