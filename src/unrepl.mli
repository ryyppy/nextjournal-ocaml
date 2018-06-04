(** Serializer for Unrepl messages *)

type payload = NoPayload

val hello_message : string -> Yojson.Basic.json

val prompt_message : unit -> Yojson.Basic.json

val exn_message : ?line:int -> string -> Yojson.Basic.json

val eval_message : payload -> Yojson.Basic.json
