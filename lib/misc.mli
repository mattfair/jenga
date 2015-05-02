
open Core.Std
open Async.Std

val special_prefix : string

val db_basename : string
val log_basename : string
val lock_basename : string
val server_basename : string
val plugin_cache_basename : string

val jenga_root_basename : string
val jenga_conf_basename : string

val in_async : f:(unit -> int Deferred.t) -> 'a
