use Mix.Config

if Mix.env == :bench do
  config :mnesia,
    dir: '/tmp/mem/bench',
    dc_dump_limit: 40,
    dump_log_write_threshold: 50000
else
  config :mnesia,
    dir: '/tmp/mem',
    dc_dump_limit: 40,
    dump_log_write_threshold: 50000
end
