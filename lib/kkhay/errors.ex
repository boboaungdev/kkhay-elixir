defmodule Kkhay.ApiError do
  defexception [:status, :message, :code, :details]

  @impl true
  def message(%{status: status, message: msg, code: nil}) do
    "Kkhay.ApiError [HTTP #{status}]: #{msg}"
  end

  def message(%{status: status, message: msg, code: code}) do
    "Kkhay.ApiError [HTTP #{status} - #{code}]: #{msg}"
  end
end

defmodule Kkhay.SignatureError do
  defexception message: "Invalid K Khay webhook signature: Request rejected."
end

