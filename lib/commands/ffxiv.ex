defmodule Kurenai.Commands.FFXIV do
  require Logger

  use Alchemy.Cogs

  alias Alchemy.{Client, Embed}

  import Embed

  @ffxiv_username System.get_env("FFXIV_USERNAME")
  @ffxiv_password System.get_env("FFXIV_PASSWORD")
  @purple_embed %Embed{color: 0xAA759F}
  @hq_emoji "<:hq1:645672031140184093>"
  @town %{
    0 => "Nowheresville",
    1 => "Limsa Lominsa",
    2 => "Gridania",
    3 => "Ul'dah",
    4 => "Ishgard",
    7 => "Kugane",
    10 => "Crystarium"
  }

  def is_hq(x), do: if(x == 1, do: @hq_emoji, else: "")

  def authenticate do
    Companion.configure_random_uid()
    Companion.login(%{username: @ffxiv_username, password: @ffxiv_password})
  end

  Cogs.def refreshtoken do
    :ok = Companion.Auth.refresh_token()
    Cogs.say("ok.")
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
        :location => x["registerTown"],
        :materia => x["materia"],
        :materias => x["materias"],
        :world => world
      }
    end)
  end

  @spec market_search(any) :: [any]
  def market_search(item) do
    Companion.characters()["accounts"]
    |> hd
    |> Map.get("characters")
    |> Enum.map(&char_market_list(&1, item["ID"]))
    |> List.flatten()
    |> Enum.sort_by(&Map.fetch(&1, :price))
    |> Enum.take(25)
  end

  Cogs.set_parser(:search, &Kurenai.Helpers.parse_quoted/1)

  Cogs.def search(item) do
    Client.trigger_typing(message.channel_id)

    item =
      if match?({_, ""}, Integer.parse(item)),
        do:
          HTTPoison.get!("https://xivapi.com/item/#{item}?columns=ID,Name,Icon").body
          |> Poison.decode!(),
        else:
          HTTPoison.get!(
            "https://xivapi.com/search?indexes=item&filters=ItemSearchCategory.ID%3E=1&columns=ID,Name,Icon&string=#{
              item
            }&limit=1"
          ).body
          |> Poison.decode!()
          |> Access.get("Results")
          |> hd

    %{"Icon" => icon_path, "Name" => item_name} = item

    try do
      item
      |> market_search()
      |> Enum.reduce(@purple_embed, fn %{
                                         :seller => seller,
                                         :price => price,
                                         :stack => stack,
                                         :hq => hq,
                                         :location => location,
                                         :world => iworld
                                       },
                                       embed ->
        field(
          embed,
          is_hq(hq) <> " #{seller}@#{iworld}",
          "**$#{price}**, x#{stack} @ " <> @town[location],
          inline: true
        )
      end)
      |> Embed.title(item_name)
      |> Embed.thumbnail("https://xivapi.com/" <> icon_path)
      |> Embed.send()
    catch
      _ -> Cogs.say("Booped. Try the command again or use `k+refreshtoken`")
    end
  end
end
