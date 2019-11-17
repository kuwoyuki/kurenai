defmodule Kurenai.Commands.FFXIV do
  require Logger

  use Alchemy.Cogs

  alias Alchemy.{Client, Embed}

  import Embed

  @ffxiv_username System.get_env("FFXIV_USERNAME")
  @ffxiv_password System.get_env("FFXIV_PASSWORD")
  @purple_embed %Embed{color: 0xAA759F}

  def authenticate do
    Companion.configure_random_uid()
    Companion.login(%{username: @ffxiv_username, password: @ffxiv_password})
  end

  Cogs.def reauthenticate do
    {:ok, details} = authenticate()
    Cogs.say("Reauthenticated. UID: " <> details[:uid])
  end

  Cogs.def listchars do
    Companion.characters()["accounts"]
    |> hd
    |> Map.get("characters")
    |> Enum.reduce(@purple_embed, fn %{"cid" => cid, "name" => name, "world" => world}, embed ->
      field(embed, "#{name}@#{world}", cid)
    end)
    |> Embed.send()
  end

  def login_char(cid) do
    res = Companion.login_character(cid)

    cond do
      res |> Map.has_key?("region") ->
        Companion.character()
        Companion.character_worlds()

      true ->
        {:error, res}
    end
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

  def char_market_list(char, item_id) do
    w = login_char(char["cid"])
    world = w["currentWorld"]

    Logger.debug(world)

    Companion.market_search(item_id, world)["entries"]
    |> Enum.map(fn x ->
      %{
        :seller => x["signatureName"],
        :price => x["sellPrice"] |> String.to_integer(),
        :stack => x["stack"],
        :hq => x["hq"],
        # TODO: show a name from Towns.csv
        :location => x["registerTown"],
        :materia => x["materia"],
        :materias => x["materias"],
        :world => world
      }
    end)
  end

  # Cogs.def search(item, world) do
  #   %{"ID" => item_id, "Icon" => icon_path, "Name" => item_name} =
  #     HTTPoison.get!(
  #       "https://xivapi.com/search?indexes=item&filters=ItemSearchCategory.ID%3E=1&columns=ID,Name,Icon&string=#{
  #         item
  #       }&limit=1"
  #     ).body
  #     |> Poison.decode!()
  #     |> Access.get("Results")
  #     |> hd

  #   market_embed = %Embed{
  #     title: item,
  #     color: 0xAA759F,
  #     thumbnail: "https://xivapi.com/" <> icon_path
  #   }

  #   Companion.characters()["accounts"]
  #   |> hd
  #   |> Map.get("characters")
  #   |> Enum.find(fn el ->
  #     el["world"] == world
  #   end)
  #   |> Access.get("cid")
  #   |> char_market_list(item_id)
  #   |> Enum.take(25)
  #   |> Enum.reduce(@purple_embed, fn %{
  #                                      :seller => seller,
  #                                      :price => price,
  #                                      :stack => stack,
  #                                      :hq => hq,
  #                                      :location => location,
  #                                      :world => world
  #                                    },
  #                                    embed ->
  #     field(embed, "#{seller}@#{world}", "HQ: #{hq}, $#{price}, x#{stack}, | loc. #{location}")
  #   end)
  #   |> Embed.title(item_name)
  #   |> Embed.thumbnail("https://xivapi.com/" <> icon_path)
  #   |> Embed.send()
  # end

  Cogs.set_parser(:search, &Kurenai.Helpers.parse_quoted/1)

  Cogs.def search(item) do
    Client.trigger_typing(message.channel_id)

    %{"ID" => item_id, "Icon" => icon_path, "Name" => item_name} =
      HTTPoison.get!(
        "https://xivapi.com/search?indexes=item&filters=ItemSearchCategory.ID%3E=1&columns=ID,Name,Icon&string=#{
          item
        }&limit=1"
      ).body
      |> Poison.decode!()
      |> Access.get("Results")
      |> hd

    Companion.characters()["accounts"]
    |> hd
    |> Map.get("characters")
    |> Enum.map(&char_market_list(&1, item_id))
    |> List.flatten()
    |> Enum.sort_by(&Map.fetch(&1, :price))
    |> Enum.take(25)
    |> Enum.reduce(@purple_embed, fn %{
                                       :seller => seller,
                                       :price => price,
                                       :stack => stack,
                                       :hq => hq,
                                       :location => location,
                                       :world => iworld
                                     },
                                     embed ->
      field(embed, seller <> "@" <> iworld, "HQ: #{hq}, $#{price}, x#{stack} @ #{location}")
    end)
    |> Embed.title(item_name)
    |> Embed.thumbnail("https://xivapi.com/" <> icon_path)
    |> Embed.send()
  end
end
