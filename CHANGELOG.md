## Changelog

## v0.3.0 (2017-01-08)
* Bugfix
  * fix elixir v1.4.0 warning
  * use correct name for lru and replacement(out)

## v0.2.0 (2016-04-01)
* Enhancements
  * totally rewrite by using heavy macros
  * add persistence support by Mnesia

## v0.1.2 (2016-03-25)
* Bugfix
  * format maxmemory_size within config.exs
  * use unique inverted key for LRU cleaners
  * readd handler when handler crash
  * add ref to distinguish handlers

## v0.1.1 (2016-03-23)
* Enhancements
  * config mem module by config.exs

## v0.1.0 (2016-03-22)
* Enhancements
  * KV cache with TTL and LRU support
