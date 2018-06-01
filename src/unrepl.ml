let hello_message lang =
  `List [
      `String "~:nextrepl/hallo";
      `Assoc [("~:lang", `String lang)]
      ]


  (**
let prompt_message =
  `List [
      `String "~:promt";
      `Null
  ]

let exn_message ?(line=0) msg =
  `List [
      `String "~:exception";
      `Assoc [
          ("~:message", msg);
          ("~:line", line)
        ]
    ]

type payload = NoPayload

let encode_payload payload =
  match payload with
  | _ -> `Null

let eval_message payload =
  `List [
      `String "~:eval";
      encode_payload(payload)
    ]
   *)
