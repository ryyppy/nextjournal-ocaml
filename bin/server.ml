type lang = OCaml | Reason

let _ =
  let lang = match Sys.argv with
    | [|_; "--reason"|] -> Reason
    | _ -> OCaml
  in
  let port = 9999 in
  let (devmode, ip_bind) = match Sys.getenv_opt "NEXTREPL_DEV_SEPARATOR" with
    | Some ("false")
    | None -> (false, "0.0.0.0")
    | Some _ -> (true, "127.0.0.1")
  in
  let string_of_lang = function
    | OCaml -> "ocaml"
    | Reason -> "reason"
  in
  print_endline ("DEVMODE - Running on " ^ ip_bind ^ ":" ^ (string_of_int port) ^ " in " ^ (string_of_lang lang) ^ " mode");
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
        | ClassType of Outcometree.out_class_type
        | ModuleType of Outcometree.out_module_type
        | TypeExtension of Outcometree.out_type_extension
        | SigItem of Outcometree.out_sig_item
        | Signature of Outcometree.out_sig_item list
        | OutPhrase of Outcometree.out_phrase
        | Error of string

      let init_toploop () =
        Topfind.add_predicates ["byte"; "toploop"];
        (* Add findlib path so Topfind is available and it won't be
           initialized twice if the user does [#use "topfind"]. *)
        Topdirs.dir_directory (Findlib.package_directory "findlib");
        Toploop.initialize_toplevel_env ()

      (* Preserve the original functions *)
      let ml_print_out_value = !Toploop.print_out_value
      let ml_print_out_type = !Toploop.print_out_type
      let ml_print_out_class_type = !Toploop.print_out_class_type
      let ml_print_out_module_type = !Toploop.print_out_module_type
      let ml_print_out_type_extension = !Toploop.print_out_type_extension
      let ml_print_out_sig_item = !Toploop.print_out_sig_item
      let ml_print_out_signature = !Toploop.print_out_signature
      let ml_print_out_phrase = !Toploop.print_out_phrase

      (* Used for mapping Outcometree.x -> Ast404.Outcometree.x *)
      let wrap f g fmt x = g fmt (f x)

      let choosePrint ml_print re_print =
        match lang with
        | OCaml -> ml_print
        | Reason -> re_print

      (**
         Pick the right print function based on the selected language
      **)
      let print_out_value =
        let re_version = wrap Reason_toolchain.From_current.copy_out_value Reason_oprint.print_out_value in
        choosePrint ml_print_out_value re_version

      let print_out_type =
        let re_version = wrap Reason_toolchain.From_current.copy_out_type Reason_oprint.print_out_type in
        choosePrint ml_print_out_type re_version

      let print_out_class_type =
        let re_version = wrap Reason_toolchain.From_current.copy_out_class_type Reason_oprint.print_out_class_type in
        choosePrint ml_print_out_class_type re_version

      let print_out_module_type =
        let re_version = wrap Reason_toolchain.From_current.copy_out_module_type Reason_oprint.print_out_module_type in
        choosePrint ml_print_out_module_type re_version

      let print_out_type_extension =
        let re_version = wrap Reason_toolchain.From_current.copy_out_type_extension Reason_oprint.print_out_type_extension in
        choosePrint ml_print_out_type_extension re_version

      let print_out_sig_item =
        let re_version = wrap Reason_toolchain.From_current.copy_out_sig_item Reason_oprint.print_out_sig_item in
        choosePrint ml_print_out_sig_item re_version

      let print_out_signature =
        let re_version = wrap (List.map Reason_toolchain.From_current.copy_out_sig_item) Reason_oprint.print_out_signature in
        choosePrint ml_print_out_signature re_version

      let print_out_phrase =
        let re_version = wrap Reason_toolchain.From_current.copy_out_phrase Reason_oprint.print_out_phrase in
        choosePrint ml_print_out_phrase re_version

      (* Useful formatter shorthands *)
      let std_fmt = Format.std_formatter
      let noop_fmt = Format.make_formatter (fun _ _ _ -> ()) ignore

      (* The Server should be stateful *)
      let _ = init_toploop ()

      let eval ?(fmt=noop_fmt) str =
        try
          (* init_toploop () ; *)
          let result = ref Initial in
          (Toploop.print_out_value := fun _ value ->
                                      print_out_value fmt value;
                                      result := OutValue value);
          (Toploop.print_out_type := fun _ value ->
                                     print_out_type fmt value;
                                     result := OutType value);
          (Toploop.print_out_class_type := fun _ value ->
                                     print_out_class_type fmt value;
                                     result := ClassType value);
          (Toploop.print_out_module_type := fun _ value ->
                                     print_out_module_type fmt value;
                                     result := ModuleType value);
          (Toploop.print_out_type_extension := fun _ value ->
                                     print_out_type_extension fmt value;
                                     result := TypeExtension value);
          (Toploop.print_out_sig_item := fun _ value ->
                                     print_out_sig_item fmt value;
                                     result := SigItem value);
          (Toploop.print_out_signature := fun _ value ->
                                     print_out_signature fmt value;
                                     result := Signature value);
          (Toploop.print_out_phrase := fun _ value ->
                                       print_out_phrase fmt value;
                                       result := OutPhrase value);

          let lex = Lexing.from_string str in
          let tpl_phrases = match lang with
            | OCaml -> Parse.use_file lex
            | Reason ->
              List.map Reason_toolchain.To_current.copy_toplevel_phrase (Reason_toolchain.RE.use_file lex)
            in
          let exec phr =
            if Toploop.execute_phrase true fmt phr
            then
              !result
            else
              Error "No result"
          in
          let rec execAll phrases =
            match phrases with
            | [] -> Error "No result"
            | [phr] -> exec phr
            | phr :: next ->
              let ret = exec phr in
              match ret with
              | Error _ -> ret
              | _ -> execAll next
          in
          execAll tpl_phrases

        with
        | Syntaxerr.Error _ -> Error "Syntax Error occurred"
        | Reason_syntax_util.Error _ -> Error "Reason Parsing Error"
        | _ -> Error ("Error while exec: " ^ str)

      let setting_up_server_socket =
        let sock = Unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
        let sockaddr = Unix.ADDR_INET (Unix.inet_addr_of_string ip_bind, port) in
        Unix.set_close_on_exec sock;
        Unix.setsockopt sock Unix.SO_REUSEADDR true;
        Unix.bind sock sockaddr;
        Unix.listen sock 20; (* max 20 pending requests *)
        sock

      let send_json out_chan str =
        Yojson.Basic.to_string str |> Printf.fprintf out_chan "%s";
        flush out_chan

      let send_hello chan =
        Nextrepl.hello_message (string_of_lang lang)|> send_json chan

      let send_prompt chan =
        Nextrepl.prompt_message () |> send_json chan

      let send_exn chan err =
        Nextrepl.exn_message err |> send_json chan

      let send_eval chan payload =
        Nextrepl.eval_message payload |> send_json chan

      (* Depending on if devmode is enabled, the termination
         character will either be \n or the actual nullbyte *)
      let rec read_until_nullbyte ?(buf=Buffer.create 16) ~in_chan () =
        match (input_char in_chan, devmode) with
        | ('\x00', false) -> Buffer.contents buf
        | ('\n', true) -> Buffer.contents buf
        | (ch, _) -> Buffer.add_char buf ch;
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
          | ClassType _
          | ModuleType _
          | TypeExtension _
          | SigItem _
          | Signature _
          | OutPhrase _ ->
            send_eval out_chan Nextrepl.NoPayload;
            send_prompt out_chan;
        done

      let process_client fd =
        let cli, _sockaddr = Unix.accept fd in

        let in_chan = Unix.in_channel_of_descr cli in
        let out_chan = Unix.out_channel_of_descr cli in

        send_hello out_chan;
        send_prompt out_chan;

        loop in_chan out_chan

      let main () =
        let fd = setting_up_server_socket in
        process_client fd
    end in

  Server.main ()
