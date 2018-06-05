type eval_result =
  | Initial
  | NoValue
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

let eval ?(fmt=noop_fmt)str =
  try
    let open Parsetree in
    init_toploop () ;
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
  | _ -> Error "Unknown error occurred"

let eval_lwt = Lwt.wrap1 eval
