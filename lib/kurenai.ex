defmodule Kurenai do
  require Logger

  use Application
  use Alchemy.Cogs

  alias Alchemy.Client

  @spec start(any, any) :: {:ok, pid}
  def start(_type, _args) do
    case System.get_env("KURENAI_TOKEN") do
      nil ->
        IO.puts("KURENAI_TOKEN not defined, cannot start.")

      token ->
        Logger.info("Logging in..")

        run = Client.start(token |> String.trim())

        Logger.debug("Logged in")
        Logger.debug("Configuring FFXIV Companion lib...")

        # TODO: this needs to be in a DB
        # Companion.configure(user_id: @ffxiv_user_id)
        Kurenai.Commands.FFXIV.authenticate()
        Logger.debug("Logged into FFXIV Companion API.")

        Cogs.set_prefix("k+")

        use Kurenai.Commands.{Basic, FFXIV}

        Logger.info("Ready to receive events.")

        run
    end
  end
end
