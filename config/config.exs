use Mix.Config

config :mnesia,
  dir: '/tmp/mem',
  dc_dump_limit: 40,
  dump_log_write_threshold: 50000
