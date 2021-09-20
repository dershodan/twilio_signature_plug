# TwilioSignaturePlug

This is a Plug that verifies authenticity of Twilio requests

It is intended to be used in pipelines in the routes.ex of your Phoenix app

## Installation

add twilio_signature_plug to your mix.exs deps

```
defp deps do
  [
    ...
    {:twilio_signature_plug, "~> 0.1"},
    # {:dep_from_hexpm, "~> 0.3.0"},
    # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ...
  ]
end
```

Add your twilio **auth_token** to your `config.exs` (e.g. from the environment as examplified here)

```
config :twilio_signature_plug,
  auth_token: System.get_env() |> Map.get("TWILIO_AUTH_TOKEN", "i am required")
```

## Example Usage

add the signature validation Plug to your Twilio Webhook pipeline like in this example:

```
pipeline :api_protected_twilio do
  plug :accepts, ["xml"]
  plug TwilioSignaturePlug, error_handler: TwilioSignatureErrorHandler
  end
```

If you are using phoenix and want the Plug to immediately respond with errors in case the signature validation failed, you can just replace `TwilioSignatureErrorHandler` with your own implementation like so:

**Note:** This library comes without a dependency to Phoenix, hence this library will only set the correct status in the `Plug.Conn` struct and set it to `halted==true`

```
defmodule YourAppWeb.TwilioSignatureErrorHandler do
  use YourAppWeb, :controller
  alias Plug.Conn

  def call(conn, :not_authenticated) do
    conn
    |> put_status(401)
    |> json(%{error: %{code: 401, message: "Not authenticated"}})
  end
  def call(conn, :bad_request) do
    conn
    |> put_status(400)
    |> json(%{error: %{code: 400, message: "Bad Request"}})
  end
end
```

## License

[MIT](./LICENSE)