use Mix.Config

config :logger,
  level: :debug

# format: "$time $metadata[$level] $message\n",
# metadata: [:request_id]

config :alchemy,
  ffmpeg_path: "/usr/bin/ffmpeg",
  youtube_dl_path: "/usr/local/bin/youtube-dl"

config :kurenai, Kurenai.Cron,
  jobs: []
