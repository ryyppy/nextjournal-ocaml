module Unrepl = Nextjournal_ocaml.Unrepl

(* Inspiration: https://stackoverflow.com/questions/32102949/working-with-ocaml-lwt-sockets?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa *)
let setting_up_server_socket =
  let sock = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  let sockaddr = Unix.ADDR_INET (Unix.inet_addr_of_string "0.0.0.0", 9999) in
  Lwt_unix.set_close_on_exec sock ;
  Lwt_unix.setsockopt sock Unix.SO_REUSEADDR true ;
  let%lwt _ = Lwt_unix.bind sock sockaddr in
  (* max 20 pending requests *)
  Lwt_unix.listen sock 20 ; Lwt.return sock


let hello_handshake chan lang =
  let msg = Yojson.Basic.to_string (Unrepl.hello_message lang) in
  Lwt_io.fprint chan msg


let process_client fd =
  let%lwt cli, _sockaddr = Lwt_unix.accept fd in
  let chan = Lwt_io.(of_fd ~mode:output cli) in
  let%lwt () = hello_handshake chan "ocaml" in
  Lwt_io.close chan


let handle_incoming =
  let%lwt fd = setting_up_server_socket in
  process_client fd


let _ = handle_incoming |> Lwt_main.run
