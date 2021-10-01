defmodule TwilioSignaturePlug do
  alias Plug.Conn
  require Logger

  @doc false
  def init(config) do
    case Keyword.get(config, :error_handler, :not_found) do
      :not_found ->
        raise "No :error_handler configuration option provided. It's required to set this when using #{inspect(__MODULE__)}."
      value -> value
    end
  end

  @doc false
  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, error_handler) do
    conn
    |> check_signature
    |> maybe_halt(conn, error_handler)
  end

  defp maybe_halt(:mismatch, conn, error_handler) do
    conn
    |> error_handler.call(:not_authenticated)
    |> Conn.halt()
  end

  defp maybe_halt(:missing, conn, error_handler) do
    conn
    |> error_handler.call(:bad_request)
    |> Conn.halt()
  end

  defp maybe_halt(:ok, conn, _handler), do: conn

  @doc """
  Generates a signature from the conn object
  twilio signatures are created from the full URI including all get and post parameters
  see https://www.twilio.com/docs/usage/security#validating-requests for details
  """
  def expected_signature(conn) do
    uri = conn |> generate_uri
    post_param_string = conn |> generate_undelimited_post_params
    complete_signed_string = "#{uri}#{post_param_string}"

    calculated_signature =
      :crypto.mac(
        :hmac,
        :sha,
        Application.get_env(:twilio_signature_plug, :auth_token),
        complete_signed_string
      )
      |> Base.encode64()
    calculated_signature
  end

  @doc """
  Compares expected signature to the twilio signature set in the headers
  """
  def check_signature(conn) do
    # is the signature correct?
    case find_twilio_signature(conn.req_headers) do
      {:ok, signature} ->
        case expected_signature(conn) == signature do
          true ->
            :ok
          false ->
            :mismatch
        end

      {:error, _reason} ->
        Logger.debug(
          "Twilio signature missing in conn.req_headers (#{__MODULE__}) - was this request really from Twilio?"
        )

        :missing
    end
  end

  defp generate_uri(conn) do
    # generates the original URI including GET parameters and scheme
    base_uri = "https://#{conn.host}#{conn.request_path}"

    case conn.query_string do
      "" ->
        # if the query string is empty, just return the base_uri
        base_uri

      _ ->
        # otherwise add the query string
        "#{base_uri}?#{conn.query_string}"
    end
  end

  defp generate_undelimited_post_params(conn) do
    Enum.sort(conn.body_params) |> concaternate_list_tuples
  end

  defp concaternate_list_tuples(list, string \\ "") do
    case list do
      [{k, v} | t] ->
        concaternate_list_tuples(t, "#{string}#{k}#{v}")

      [] ->
        string
    end
  end

  defp find_twilio_signature(headers) do
    case headers do
      [{"x-twilio-signature", signature} | _] ->
        {:ok, signature}

      [_ | t] ->
        find_twilio_signature(t)

      [] ->
        {:error, "Twilio Signature not found!"}
    end
  end
end
