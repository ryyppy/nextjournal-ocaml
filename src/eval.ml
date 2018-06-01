type eval_result =
  | Initial
  | NoValue
  | OutValue of Outcometree.out_value
  | Error of string

let init_toploop () = Toploop.initialize_toplevel_env ()

let noop_formatter = Format.make_formatter (fun _ _ _ -> ()) ignore

(* let print_item item =
 *   let open Parsetree in
 *   let {pstr_desc; _} = item in
 *   match pstr_desc with _ -> print_endline "whatever"
 *
 *
 * let print_structure structure =
 *   let item = List.nth_opt structure 0 in
 *   match item with
 *   | Some item' -> print_item item'
 *   | None -> print_endline "no structure found" *)
(* Keep the original impl for now *)
let default_print_out_value = !Toploop.print_out_value

(* New hook to get data *)
(* let hook_out_value set_result _formatter (out_value: Outcometree.out_value) =
 *   set_result (OutValue out_value) *)

let print_out_value out_value =
  let open Outcometree in
  match out_value with
  | Oval_int i -> print_endline ("Int: " ^ string_of_int i)
  | Oval_string (s, _, _) -> print_endline ("String: " ^ s)
  | _ -> print_endline "out_value not handled"

let eval str =
  try
    let open Parsetree in
    init_toploop () ;
    let result = ref Initial in
    (Toploop.print_out_value := fun _ value -> result := OutValue value) ;
    let lex = Lexing.from_string str in
    let tpl_phrase = Ptop_def (Parse.implementation lex)
    in
    if Toploop.execute_phrase true noop_formatter tpl_phrase
    then
      !result
    else
      Error "No result"
  with Syntaxerr.Error _ ->
      Error "Syntax Error occurred"

let eval_lwt = Lwt.wrap1 eval
