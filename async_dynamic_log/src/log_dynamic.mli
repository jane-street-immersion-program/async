open! Core
open! Async
open! Async_unix

type t

val create
  :  level:Log.Level.t
  -> output:Log.Output.t list
  -> on_error:[ `Raise | `Call of Core.Error.t -> unit ]
  -> ?time_source:Async_kernel.Synchronous_time_source.t
  -> ?transform:(Log.Message.t -> Log.Message.t)
  -> ?listener_file_path:string
  -> unit
  -> t

module Make_global_dynamic () : Log.Global_intf

val debug_s
  :  ?time:Core.Time_float.t
  -> ?tags:(string * string) list
  -> t
  -> Sexp.t
  -> unit

val info_s
  :  ?time:Core.Time_float.t
  -> ?tags:(string * string) list
  -> t
  -> Sexp.t
  -> unit

val error_s
  :  ?time:Core.Time_float.t
  -> ?tags:(string * string) list
  -> t
  -> Sexp.t
  -> unit

module Global_dynamic_log : sig
  include Async_unix.Log.Global_intf

  val set_listener : string -> unit Deferred.t
end