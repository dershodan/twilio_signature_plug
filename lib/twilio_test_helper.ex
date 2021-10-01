defmodule TwilioSignaturePlug.TwilioTestHelper do
  @doc """
  Set the rquired twilio signature header in a Conn object
  This is designed for testing requests to twilio-signature-plug protected routes.
  """
  def sign_conn(%{} = conn) do
    signature = TwilioSignaturePlug.expected_signature(conn)

    case conn do
      %{:req_headers => headers} ->
        # update the headers
        %{conn | req_headers: set_twilio_signature_header(headers, signature)}

      _ ->
        # if no headers were set, we create them
        %{conn | req_headers: [{"x-twilio-signature", signature}]}
    end
  end

  defp set_twilio_signature_header(headers, signature) do
    [
      {"x-twilio-signature", signature}
      | headers
        |> Enum.filter(fn x ->
          case x do
            {"x-twilio-signature", _} -> false
            {_, _} -> true
          end
        end)
    ]
  end
end
