val send_hello: Lwt_io.output Lwt_io.channel -> string -> unit Lwt.t

val send_prompt: Lwt_io.output Lwt_io.channel -> unit Lwt.t

val send_exn: Lwt_io.output Lwt_io.channel -> string -> unit Lwt.t
