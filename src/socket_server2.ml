let setting_up_server_socket =
  let sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
  let sockaddr = Unix.ADDR_INET (Unix.inet_addr_of_string "0.0.0.0", 9999) in
  Unix.set_close_on_exec sock;
  Unix.setsockopt sock Unix.SO_REUSEADDR true;
  Unix.bind sock sockaddr;
  Unix.listen sock 20; (* max 20 pending requests *)
  sock

let send_json out_chan str =
  Yojson.Basic.to_string str |> Printf.fprintf out_chan "%s";
  flush out_chan

let send_hello chan lang =
  Unrepl.hello_message lang |> send_json chan

let send_prompt chan =
  Unrepl.prompt_message () |> send_json chan

let send_exn chan err =
  Unrepl.exn_message err |> send_json chan

let send_eval chan payload =
  Unrepl.eval_message payload |> send_json chan

let print_out_value = Eval.default_print_out_value (Format.formatter_of_out_channel stdout)

let foo v =
  let open Outcometree in
  match v with
  | Oval_int i -> print_endline (string_of_int i)
  | _ -> print_endline "Unknown out_value"

let print_result result =
  let open Eval in
  match result with
  | OutValue v -> foo v
  | NoValue -> print_endline "There was no result"
  | Error s -> Printf.printf "Error: %s" s
  | _ -> print_endline "unhandled case"

let rec read_until_nullbyte ?(buf=Buffer.create 16) ~in_chan () =
  match input_char in_chan with
  | '\n' -> Buffer.contents buf
  | ch -> Buffer.add_char buf ch;
          read_until_nullbyte ~buf ~in_chan ()
  | exception End_of_file -> Buffer.contents buf

let rec loop in_chan out_chan =
  (* Wait until EOF and read all lines separated with \n etc. *)
  let program = read_until_nullbyte ~in_chan () in

  let result = Eval.eval program in

  let () = match result with
    | Error msg -> send_exn out_chan msg;
                   send_prompt out_chan;
    | _ -> print_result result;
           send_eval out_chan Unrepl.NoPayload;
           send_prompt out_chan;
  in
  loop in_chan out_chan

let process_client fd =
  let cli, _sockaddr = Unix.accept fd in

  let in_chan = Unix.in_channel_of_descr cli in
  let out_chan = Unix.out_channel_of_descr cli in

  send_hello out_chan "ocaml";
  send_prompt out_chan;

  loop in_chan out_chan;
