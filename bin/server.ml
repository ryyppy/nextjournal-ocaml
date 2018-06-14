let _ =
  let module Nextrepl : sig
        type payload = NoPayload

        val hello_message : string -> Yojson.Basic.json
        val prompt_message : unit -> Yojson.Basic.json
        val exn_message : ?line:int -> string -> Yojson.Basic.json
        val eval_message : payload -> Yojson.Basic.json

      end = struct
      let hello_message lang =
        `List [
            `String "~:nextrepl/hello";
            `Assoc [("~:lang", `String lang)]
          ]

      let prompt_message () =
        `List [
            `String "~:prompt";
            `Null
          ]

      let exn_message ?(line=0) msg =
        `List [
            `String "~:exception";
            `Assoc [
                ("~:message", `String msg);
                ("~:line", `Int line)
              ]
          ]

      type payload = NoPayload

      let encode_payload payload =
        match payload with
        | _ -> `Null

      (* check out clojure transit protocol for serialization logic *)
      let eval_message payload =
        `List [
            `String "~:eval";
            encode_payload(payload)
          ]
    end in
  let module Server : sig
        val main : unit -> unit
      end = struct
      type eval_result =
        | Initial
        | OutValue of Outcometree.out_value
        | OutType of Outcometree.out_type
        | OutPhrase of Outcometree.out_phrase
        | Error of string

      let init_toploop () = Toploop.initialize_toplevel_env ()

      (* Preserve the original functions *)
      let default_print_out_value = !Toploop.print_out_value
      let default_print_out_type = !Toploop.print_out_type
      let default_print_out_phrase = !Toploop.print_out_phrase

      (* Useful formatter shorthands *)
      let std_fmt = Format.std_formatter
      let noop_fmt = Format.make_formatter (fun _ _ _ -> ()) ignore

      (* The Server should be stateful *)
      let _ = init_toploop ()

      let eval ?(fmt=noop_fmt) str =
        try
          let open Parsetree in
          (* init_toploop () ; *)
          let result = ref Initial in
          (Toploop.print_out_value := fun _ value ->
                                      default_print_out_value fmt value;
                                      result := OutValue value);
          (Toploop.print_out_type := fun _ value ->
                                     default_print_out_type fmt value;
                                     result := OutType value);
          (Toploop.print_out_phrase := fun _ value ->
                                       default_print_out_phrase fmt value;
                                       result := OutPhrase value);
          let lex = Lexing.from_string str in
          let tpl_phrase = Ptop_def (Parse.implementation lex)
          in
          if Toploop.execute_phrase true fmt tpl_phrase
          then
            !result
          else
            Error "No result"
        with
        | Syntaxerr.Error _ -> Error "Syntax Error occurred"
        | _ -> Error ("Error while exec: " ^ str)

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
        Nextrepl.hello_message lang |> send_json chan

      let send_prompt chan =
        Nextrepl.prompt_message () |> send_json chan

      let send_exn chan err =
        Nextrepl.exn_message err |> send_json chan

      let send_eval chan payload =
        Nextrepl.eval_message payload |> send_json chan

      let rec read_until_nullbyte ?(buf=Buffer.create 16) ~in_chan () =
        match input_char in_chan with
        | '\x00' -> Buffer.contents buf
        | ch -> Buffer.add_char buf ch;
                read_until_nullbyte ~buf ~in_chan ()
        | exception End_of_file -> Buffer.contents buf

      let loop in_chan out_chan =
        let quit _ = exit 0 |> ignore in
        Sys.(
          signal sigint (Signal_handle quit) |> ignore;
          signal sigpipe (Signal_handle quit) |> ignore;
        );
        while true do
          (* Wait until EOF and read all lines separated with \n etc. *)
          let program = read_until_nullbyte ~in_chan () in
          let fmt = std_fmt in
          let result = eval ~fmt program in

          match result with
          | Error msg -> send_exn out_chan msg;
            send_prompt out_chan;
          | Initial
          | OutValue _
          | OutType _
          | OutPhrase _ ->
            send_eval out_chan Nextrepl.NoPayload;
            send_prompt out_chan;
        done


      let process_client fd =
        let cli, _sockaddr = Unix.accept fd in

        let in_chan = Unix.in_channel_of_descr cli in
        let out_chan = Unix.out_channel_of_descr cli in

        send_hello out_chan "ocaml";
        send_prompt out_chan;

        loop in_chan out_chan

      let main () =
        let fd = setting_up_server_socket in
        process_client fd
    end in

  Server.main ()
