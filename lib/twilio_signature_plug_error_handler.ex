defmodule TwilioSignaturePlugErrorHandler do
  @moduledoc """
  This Error handler will just set the satus of the given Plug.Conn to the respective error code
  400 in case the twilio signature was completely missing
  401 in case the signature doesn't match

  In the context of a phoenix application you likely want to respond when this check fails. This is not included
  so this package doesn't need phoenix as a dependency
  Just create a new SignaturePlugErrorHandler in your application, that will include the commented lines or similar
  """

  # use YourAppWeb, :controller
  import Plug.Conn

  def call(conn, :not_authenticated) do
    conn
    |> Conn.put_status(401)
    # |> json(%{error: %{code: 401, message: "Not authenticated"}})
  end
  def call(conn, :bad_request) do
    conn
    |> Conn.put_status(400)
    # |> json(%{error: %{code: 400, message: "Bad Request"}})
  end
end
