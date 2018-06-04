(* Inspiration: https://stackoverflow.com/questions/32102949/working-with-ocaml-lwt-sockets?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa *)
let setting_up_server_socket =
  let sock = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  let sockaddr = Unix.ADDR_INET (Unix.inet_addr_of_string "0.0.0.0", 9999) in
  Lwt_unix.set_close_on_exec sock ;
  Lwt_unix.setsockopt sock Unix.SO_REUSEADDR true;
  let%lwt _ = Lwt_unix.bind sock sockaddr in
  (* max 20 pending requests *)
  Lwt_unix.listen sock 20 ; Lwt.return sock

let send_json chan str =
  Yojson.Basic.to_string str |> Lwt_io.fprint chan

let send_hello chan lang =
  Unrepl.hello_message lang |> send_json chan

let send_prompt chan =
  Unrepl.prompt_message () |> send_json chan

let send_exn chan err =
  Unrepl.exn_message err |> send_json chan

let send_eval chan payload =
  Unrepl.eval_message payload |> send_json chan

(* let lwt_print_out_value out_value =
 *   let open Outcometree in
 *   match out_value with
 *   | Oval_int i -> Lwt_io.printl ("Int: " ^ string_of_int i)
 *   | Oval_string (s, _, _) -> Lwt_io.printl ("String: " ^ s)
 *   | _ -> Lwt_io.printl "out_value not handled" *)

let lwt_print_out_value =
  Lwt.wrap1 (Eval.default_print_out_value Format.std_formatter)

let print_result result =
  let open Eval in
  match result with
  | OutValue v -> lwt_print_out_value v
  | NoValue -> Lwt_io.printl "There was no result"
  | Error s -> Lwt_io.printlf "Error: %s" s
  | _ -> Lwt_io.printl "unhandled case"


let rec read_until_nullbyte ?(buf=Buffer.create 16) ~in_chan () =
  let%lwt ch = Lwt_io.read_char_opt in_chan in
  match ch with
  | Some ch ->
     if ch = '\n' then
       Lwt.return (Buffer.contents buf)
     else begin
       Buffer.add_char buf ch;
       read_until_nullbyte ~buf ~in_chan ()
     end
  | None -> Lwt.return (Buffer.contents buf)


let rec loop in_chan out_chan =
  try%lwt
    (* Wait until EOF and read all lines separated with \n etc. *)
    let%lwt program = read_until_nullbyte ~in_chan () in

    let%lwt () = Lwt_io.printlf "Program:\n%s" program in
    let%lwt result = Eval.eval_lwt program in

    let%lwt () = match result with
      | Error msg -> Lwt.join [
                         send_exn out_chan msg;
                         send_prompt out_chan;
                       ]
      | _ ->
          Lwt.join [
              send_prompt out_chan;
              send_eval out_chan Unrepl.NoPayload;
              print_result result;
            ]
    in
    loop in_chan out_chan
  with _ ->
    Lwt.return_unit

let process_client fd =
  (* Establish the connection and get a connected file descriptor *)
  let%lwt cli, _sockaddr = Lwt_unix.accept fd in

  (* Open two channels for reading / writing *)
  let out_chan = Lwt_io.(of_fd ~mode:output cli) in
  let in_chan = Lwt_io.(of_fd ~mode:input cli) in

  (* Comply to the protocol, send an initial hello & prompt message *)
  let%lwt () = send_hello out_chan "ocaml" in
  let%lwt () = send_prompt out_chan in

  let%lwt () = loop in_chan out_chan in

  Lwt_io.close out_chan
