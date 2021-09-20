defmodule TwilioSignaturePlugTest do
  use ExUnit.Case

  defmodule TestTwilioSignatureErrorHandler do
    @moduledoc """
    This is just a ErrorHandler that won't cause Responses
    so in our tests the conn remains easy to check
    """
    alias Plug.Conn

    @spec call(Conn.t(), :not_authenticated) :: Conn.t()
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

  setup do
    orig_token = Application.get_env(:twilio_signature_plug, :auth_token)
    Application.put_env(:twilio_signature_plug, :auth_token, "d0fddb8939d228ed08f01b8636bf80fd")

    conn = %Plug.Conn{
      assigns: %{current_user: nil},
      body_params: %{
        "AccountSid" => "AC580a2a2f18195ba92095bd3c23416477",
        "ApiVersion" => "2010-04-01",
        "CallSid" => "CA919c110287326021105be625cb181824",
        "CalledState" => "LA",
        "CalledZip" => "",
        "Caller" => "+1123456789",
        "CallerCity" => "",
        "CallerCountry" => "US",
        "FromZip" => "",
        "To" => "+1987654321",
        "CallerState" => "",
        "CallerZip" => "",
        "CallStatus" => "ringing",
        "Called" => "+1987654321",
        "CalledCity" => "",
        "CalledCountry" => "US",
        "Direction" => "inbound",
        "From" => "+1123456789",
        "FromCity" => "",
        "FromCountry" => "US",
        "FromState" => "",
        "ToCity" => "",
        "ToCountry" => "US",
        "ToState" => "LA",
        "ToZip" => ""
      },
      cookies: %{},
      halted: false,
      host: "host@example.org",
      method: "POST",
      params: %{
        "AccountSid" => "AC580a2a2f18195ba92095bd3c23416477",
        "ApiVersion" => "2010-04-01",
        "CallSid" => "CA919c110287326021105be625cb181824",
        "CallStatus" => "ringing",
        "Called" => "+1987654321",
        "CalledCity" => "",
        "CalledCountry" => "US",
        "CalledState" => "LA",
        "CalledZip" => "",
        "Caller" => "+1123456789",
        "CallerCity" => "",
        "CallerCountry" => "US",
        "CallerState" => "",
        "CallerZip" => "",
        "Direction" => "inbound",
        "From" => "+1123456789",
        "FromCity" => "",
        "FromCountry" => "US",
        "FromState" => "",
        "FromZip" => "",
        "To" => "+1987654321",
        "ToCity" => "",
        "ToCountry" => "US",
        "ToState" => "LA",
        "ToZip" => ""
      },
      path_info: ["api", "v1", "call"],
      path_params: %{},
      port: 80,
      query_params: %{},
      query_string: "",
      remote_ip: {172, 18, 0, 1},
      req_cookies: %{},
      req_headers: [
        {"accept-encoding", "gzip"},
        {"content-length", "425"},
        {"content-type", "application/x-www-form-urlencoded; charset=UTF-8"},
        {"host", "host@example.org"},
        {"i-twilio-idempotency-token", "7a838604-9676-4cc7-8561-f3ecf62c6f55"},
        {"user-agent", "TwilioProxy/1.1"},
        {"x-forwarded-for", "54.172.179.110"},
        {"x-forwarded-proto", "https"},
        {"x-twilio-signature", "ljKsqL2C3vW6GTX9zPB3fkBdb1o="}
      ],
      request_path: "/api/v1/call",
      resp_body: nil,
      resp_cookies: %{},
      resp_headers: [
        {"cache-control", "max-age=0, private, must-revalidate"},
        {"x-request-id", "FqT04sZz5fU8hU8AABLF"}
      ],
      scheme: :http,
      script_name: [],
      state: :unset,
      status: nil
    }

    # re-set the token
    on_exit(fn -> Application.put_env(:twilio_signature_plug, :auth_token, orig_token) end)

    {:ok, conn: conn}
  end

  test "valid request and signature", context do
    conn = context[:conn]
    |> TwilioSignaturePlug.call(TestTwilioSignatureErrorHandler)
    refute conn.halted
  end

  test "invalid signature", context do
    conn = %{context[:conn] | req_headers: [
      {"accept-encoding", "gzip"},
      {"content-length", "425"},
      {"content-type", "application/x-www-form-urlencoded; charset=UTF-8"},
      {"host", "host@example.org"},
      {"i-twilio-idempotency-token", "7a838604-9676-4cc7-8561-f3ecf62c6f55"},
      {"user-agent", "TwilioProxy/1.1"},
      {"x-forwarded-for", "54.172.179.110"},
      {"x-forwarded-proto", "https"},
      {"x-twilio-signature", "incorrect_signature"}
    ]} |> TwilioSignaturePlug.call(TestTwilioSignatureErrorHandler)
    assert conn.status == 401
    assert conn.halted
  end

  test "changed path", context do
    conn = %{context[:conn] | request_path: "/api/v1/callWRONG"}
    |> TwilioSignaturePlug.call(TestTwilioSignatureErrorHandler)
    assert conn.status == 401
    assert conn.halted
  end

  test "changed query string", context do
    conn = %{context[:conn] | query_string: "?CHANGE=WRONG"}
    |> TwilioSignaturePlug.call(TestTwilioSignatureErrorHandler)
    assert conn.status == 401
    assert conn.halted
  end

  test "changed body params", context do
    conn = %{context[:conn] | body_params: %{
      "AccountSid" => "AC580a2a2f18195ba92095bd3c23416477",
      "ApiVersion" => "2010-04-01",
      "Some" => "CHANGES",
      "FromCountry" => "US",
      "FromState" => "",
      "ToCity" => "",
      "ToCountry" => "US",
      "ToState" => "LA",
      "ToZip" => ""
    }} |> TwilioSignaturePlug.call(TestTwilioSignatureErrorHandler)
    assert conn.status == 401
    assert conn.halted
  end

  test "changing body params order doesnt matter", context do
    conn = %{context[:conn] | body_params: %{
      "CalledZip" => "",
      "Caller" => "+1123456789",
      "CallerCity" => "",
      "CallerCountry" => "US",
      "FromZip" => "",
      "AccountSid" => "AC580a2a2f18195ba92095bd3c23416477",
      "To" => "+1987654321",
      "CallerState" => "",
      "CallerZip" => "",
      "CallStatus" => "ringing",
      "ApiVersion" => "2010-04-01",
      "FromCountry" => "US",
      "FromState" => "",
      "CallSid" => "CA919c110287326021105be625cb181824",
      "ToCountry" => "US",
      "CalledState" => "LA",
      "Called" => "+1987654321",
      "CalledCity" => "",
      "From" => "+1123456789",
      "FromCity" => "",
      "ToCity" => "",
      "ToState" => "LA",
      "ToZip" => "",
      "CalledCountry" => "US",
      "Direction" => "inbound",
    }} |> TwilioSignaturePlug.call(TestTwilioSignatureErrorHandler)
    # order of the body_params doesn't matter
    refute conn.halted
  end

  test "twilio signature missing", context do
    conn = %{context[:conn] | req_headers: [
      {"accept-encoding", "gzip"},
      {"content-length", "425"},
      {"content-type", "application/x-www-form-urlencoded; charset=UTF-8"},
      {"host", "host@example.org"},
      {"i-twilio-idempotency-token", "7a838604-9676-4cc7-8561-f3ecf62c6f55"},
      {"user-agent", "TwilioProxy/1.1"},
      {"x-forwarded-for", "54.172.179.110"},
      {"x-forwarded-proto", "https"},
      # {"x-twilio-signature", "incorrect_signature"} Twilio  signature missing
    ]} |> TwilioSignaturePlug.call(TestTwilioSignatureErrorHandler)
    assert conn.status == 400
    assert conn.halted
  end
end
