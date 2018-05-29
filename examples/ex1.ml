open Eval

let print_result = function
  | OutValue v -> print_out_value v
  | NoValue -> print_endline "There was no result"
  | Error -> print_endline "An unexpected error occurred"
  | _ -> print_endline "unhandled case"

let case1 () =
  eval "1 + 2;;" |> print_result

let case2 () =
  eval2 "let _ = 1;; let a = b + 1 in \"test \" ^ (string_of_int a)" |> print_result

let _ =
  case1 ();
  (* case2 (); *)
