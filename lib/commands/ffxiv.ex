defmodule Kurenai.Commands.FFXIV do
  use Alchemy.Cogs

  alias Alchemy.{Client, Embed}
  import Embed

  @purple_embed %Embed{color: 0xAA759F}

  Cogs.def listchars do
    Companion.characters()["accounts"]
    |> hd
    |> Map.get("characters")
    |> Enum.reduce(@purple_embed, fn %{"cid" => cid, "name" => name, "world" => world}, embed ->
      field(embed, "#{name}@#{world}", cid)
    end)
    |> Embed.send()
  end

  Cogs.def loginchar(cid) do
    res = Companion.login_character(cid)

    cond do
      res |> Map.has_key?("region") ->
        char = Companion.API.Base.request(:get, "login/character")

        @purple_embed
        |> Embed.title("Logged in")
        |> Embed.description(char["character"]["name"] <> "@" <> char["character"]["world"])
        |> Embed.thumbnail(
          "https://img2.finalfantasyxiv.com/f/" <>
            char["character"]["portrait"] <> "fc0_96x96.jpg"
        )
        |> Embed.send()

      true ->
        Cogs.say("boop.")
    end
  end

  Cogs.def search(item) do
    world = Companion.character_worlds() |> Map.get("currentWorld")

    Companion.market_search(item, world)["entries"]
    |> Enum.reduce(@purple_embed, fn %{
                                       "registerTown" => location,
                                       "signatureName" => seller,
                                       "stack" => stack,
                                       "hq" => hq,
                                       "sellPrice" => price
                                     },
                                     embed ->
      field(embed, "#{seller}@#{world}", "HQ: #{hq}, Price: #{price}, x#{stack} @ #{location}")
    end)
    |> Embed.title("#{world} #{item} marketboard search")
    |> Embed.send()
  end
end
