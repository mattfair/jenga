
open Core.Std
open Async.Std

module Digester : sig
  val init : Config.t -> unit (* just once *)
end

(* Module supporting interface to file-system -- stat, digest, glob.
   Services: Digest caching & inotify wrapping (as hearts).
*)

val lstat_counter : Effort.Counter.t
val digest_counter : Effort.Counter.t
val ls_counter : Effort.Counter.t
val mkdir_counter : Effort.Counter.t

module Digest = Db.Digest
module Kind = Db.Kind

module Glob : sig (* glob specification *)
  type t = Db.Glob.t with sexp, bin_io, compare
  include Hashable with type t := t
  val dir : t -> Path.t
  val pattern : t -> Pattern.t
  val kind_allows_file : t -> bool
  val to_string : t -> string
  val create : dir:Path.t -> ?kinds: Kind.t list -> string -> t
  (** matches exactly one path *)
  val create_from_path : kinds:Kind.t list option -> Path.t -> t
end

module Listing = Db.Listing

type t (* handle to the file-system *)
val create : Config.t -> Persist.t -> t Deferred.t

module Contents_result : sig
  type t = [
  | `file_read_error of Error.t
  | `is_a_dir
  | `contents of string
  ]
end

module Digest_result : sig
  type t = [
  | `stat_error of Error.t
  | `is_a_dir
  | `undigestable of Kind.t
  | `digest_error of Error.t
  | `digest of Digest.t
  ]
end

module Listing_result : sig
  type t = [
  | `stat_error of Error.t
  | `not_a_dir
  | `listing_error of Error.t
  | `listing of Listing.t
  ]
end

module Ensure_directory_result : sig
  type t = [`ok | `failed | `not_a_dir]
end

val contents_file : t -> file:Path.t -> Contents_result.t Tenacious.t
val digest_file : t -> file:Path.t -> Digest_result.t Tenacious.t
val list_glob : t -> Glob.t -> Listing_result.t Tenacious.t
val ensure_directory : t -> dir:Path.t -> Ensure_directory_result.t Tenacious.t

(** Locks [targets] for writing and masks the corresponding 'file changed' messages *)
val lock_targets_and_mask_updates :
  t -> targets:Path.Rel.t list -> (unit -> 'a Deferred.t) -> 'a Deferred.t

val clear_watcher_cache : t -> Path.t -> unit

module Mtime : sig
  type t with compare
  val equal : t -> t -> bool
end

val mtime_file : t -> file:Path.t -> Mtime.t option Tenacious.t (* [None] - no file *)
val mtime_file_right_now : file:Path.t -> Mtime.t option Deferred.t (* avoiding cache *)
