open Nextjournal_ocaml.Socket_server2

let handle_incoming () =
  let fd = setting_up_server_socket in
  process_client fd

let _ =
  handle_incoming ()
