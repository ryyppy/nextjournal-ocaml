(** Serializer for Unrepl messages *)
val hello_message : string -> Yojson.Basic.json

val prompt_message : unit -> Yojson.Basic.json

val exn_message : ?line:int -> string -> Yojson.Basic.json
