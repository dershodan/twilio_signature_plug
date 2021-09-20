defmodule TwilioSignaturePlugErrorHandler do
  @moduledoc """
  This Error handler will just set the satus of the given Plug.Conn to the respective error code
  400 in case the twilio signature was completely missing
  401 in case the signature doesn't match

  In the context of a phoenix application you likely want to respond when this check fails. This is not included
  so this package doesn't need phoenix as a dependency

  See the README for more info
  """

  import Plug.Conn

  def call(conn, :not_authenticated) do
    conn
    |> Conn.put_status(401)
  end

  def call(conn, :bad_request) do
    conn
    |> Conn.put_status(400)
  end
end
