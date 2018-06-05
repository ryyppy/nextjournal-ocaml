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
