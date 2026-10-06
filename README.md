# K Khay Elixir SDK 💧

Official Elixir and Phoenix SDK for the **[K Khay Sovereign Crypto Payment Gateway](https://kkhay.com)**.

Accept non-custodial and custodial crypto payments (USDT, USDC, BNB, ETH on BSC, Polygon, Arbitrum, Base, Ethereum) in **Phoenix** web applications and distributed Elixir OTP nodes.

---

## 📦 Installation

Add `kkhay` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kkhay, "~> 1.0.0"}
  ]
end
```

---

## ⚡ Quick Start

```elixir
client = Kkhay.client(System.get_env("KKHAY_API_KEY"))

{:ok, response} =
  Kkhay.create_invoice(client, %{
    priceAmount: 49.99,
    priceCurrency: "USD",
    payNetwork: "bsc",
    payToken: "USDT",
    orderId: "ORDER-7711",
    title: "Elixir Course Access",
    customerEmail: "elixirdev@example.com",
    redirectUrl: "https://myshop.com/success"
  })

invoice = response["invoice"]
IO.puts("Invoice ID: #{invoice["id"]}")
IO.puts("Checkout URL: #{invoice["hostedUrl"]}")
```

---

## 🔐 Webhook / IPN Verification (Phoenix Controller)

```elixir
defmodule MyAppWeb.KkhayWebhookController do
  use MyAppWeb, :controller
  alias Kkhay.Webhook

  def handle(conn, _params) do
    {:ok, raw_body, conn} = Plug.Conn.read_body(conn)
    signature = Plug.Conn.get_req_header(conn, "x-kkhay-signature") |> List.first()
    secret = System.get_env("KKHAY_IPN_SECRET")

    case Webhook.parse_event(raw_body, signature, secret) do
      {:ok, event} ->
        if event["event"] == "payment.finished" do
          # Mark order as completed in database
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

## 📄 License

MIT © [K Khay](https://kkhay.com)

