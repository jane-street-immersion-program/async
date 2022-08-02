open! Core
open! Async
include Async_unix.Log
open! Async_inotify

(* create a dynamic_log.t expose only what y2ou need but is seperate from the
   log *)

let update_level file_path log =
  let%bind.Deferred () = Clock.after (Time_float_unix.Span.of_int_ms 50) in
  let%map.Deferred file_contents = Async.Reader.file_contents file_path in
  match
    Or_error.try_with (fun () ->
        let x = Log.Level.of_string file_contents in
        set_level log x)
  with
  | Ok () ->
    Core.print_endline ("Current level: " ^ Log.Level.to_string (level log))
  | Error e -> print_s [%message (e : Error.t)]
;;

let set_listener file_path log =
  let%bind _, _, inotify_pipe =
    Async_inotify.create ~events:[ Event.Selector.Modified ] file_path
  in
  let%bind () = update_level file_path log in
  Pipe.iter inotify_pipe ~f:(fun _ -> update_level file_path log)
;;

let create
    ~level
    ~output
    ~on_error
    ?time_source
    ?transform
    ?listener_file_path
    ()
  =
  match listener_file_path with
  | None -> Log.create ~level ~output ~on_error ?time_source ?transform ()
  | Some n ->
    let l = Log.create ~level ~output ~on_error ?time_source ?transform () in
    upon (set_listener n l) (fun () -> ());
    l
;;

module Make_global_dynamic () : sig
  include Async_unix.Log.Global_intf

  val set_listener : string -> unit Deferred.t
end = struct
  include Async_unix.Log.Make_global ()

  let set_listener file_path = set_listener file_path (Lazy.force log)
end

module Global_dynamic_log = Make_global_dynamic ()
