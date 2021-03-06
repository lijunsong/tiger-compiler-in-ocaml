(** This module defines the Intermediate Representation (IR) of the
    tiger compiler. *)

type exp =
  | CONST of int
  | NAME of Temp.label
  | TEMP of Temp.temp
  | BINOP of binop * exp * exp
  | MEM of exp
  (** memory operation. MEM means store only on the left side of MOVE;
      it means fetch in other cases *)
  | CALL of exp * exp list
  (** [function arguments] *)
  | ESEQ of stmt * exp
  (** evaluate stmt and then return the result of exp *)
and stmt =
  | MOVE of exp * exp (** dst, src *)
  | EXP of exp  (** evaluate e and discard the result *)
  | JUMP of exp * Temp.label list
  (** jump to exp, which has a possible location specified in the
      list *)
  | CJUMP of relop * exp * exp * Temp.label * Temp.label
  (** CJUMP(o, e1, e2, t, f), evaluate o(e1, e2), jump to t if true, f
      if false*)
  | SEQ of stmt * stmt
  | LABEL of Temp.label
and binop =
  | PLUS | MINUS | MUL | DIV
  | AND | OR | LSHIFT | RSHIFT | ARSHIFT | XOR
and relop =
  | EQ | NE | LT | GT | LE | GE
  | ULT | ULE | UGT | UGE

let rec children = function
  | MOVE (e0, e1) -> [e0; e1]
  | EXP (e) -> [e]
  | JUMP (e,_) -> [e]
  | CJUMP (_, e0, e1, _, _) -> [e0; e1]
  | SEQ (s1, s2) -> (children s1) @ (children s2)
  | LABEL (_) -> []

(** chain stmts list by SEQ *)
let rec seq stmts : stmt = match stmts with
  | [] -> EXP(CONST(0))
  | hd :: [] -> hd
  | hd :: tl ->
    SEQ(hd, seq tl)

let flip_op = function
  | EQ -> NE
  | NE -> EQ
  | LT -> GE
  | LE -> GT
  | GE -> LT
  | GT -> LE
  | _ -> failwith "NYI"

let flip_cjump stmt : stmt = match stmt with
  | CJUMP (op, e1, e2, t, f) ->
    CJUMP (flip_op op, e1, e2, f, t)
  | _ -> raise (Invalid_argument "argument is not a CJUMP.")

and binop_to_string = function
  | PLUS -> "+"
  | MINUS -> "-"
  | MUL -> "x"
  | DIV -> "/"
  | _ -> failwith "NYI"
and relop_to_string = function
  | EQ -> "="
  | NE -> "<>"
  | LT -> "<"
  | GT -> ">"
  | LE -> "<="
  | GE -> ">="
  | _ -> failwith "NYI"

let get_op = function
  | BINOP (op, _, _) -> op
  | _ -> failwith "unreachable"

let rec exp_to_doc e =
  let open Pprint in
  let open Printf in
  let comma = text "," in
  match e with
  | CONST n -> text (string_of_int n)
  | NAME l -> text (sprintf "NAME(%s)" (Temp.label_to_string l))
  | TEMP t -> text (Temp.temp_to_string t)
  | BINOP (op, e0, e1) ->
    text "BINOP("
    <-> nest 6 (text (binop_to_string op) <-> comma
                <-> exp_to_doc e0 <-> comma
                <-> exp_to_doc e1
                <-> text ")")
  | MEM (m) ->
    text "MEM(" <-> nest 4 (exp_to_doc m <-> text ")")
  | CALL (f, args) ->
    text "CALL("
    <-> nest 5 (exp_to_doc f <-> comma
                <-> line
                <-> concat comma (List.map exp_to_doc args)
                <-> text ")")
  | ESEQ (s, e) ->
    text "ESEQ("
    <-> nest 5 (stmt_to_doc s <-> comma
                <-> line
                <-> (exp_to_doc e)
                <-> (text ")"))

and stmt_to_doc stmt =
  let open Pprint in
  let open Printf in
  let comma = text "," in
  match stmt with
  | MOVE (dst, src) ->
    text "MOVE("
    <-> nest 5 (exp_to_doc dst
                <-> comma
                <-> exp_to_doc src
                <-> text ")")
  | EXP e ->
    text "EXP("
    <-> nest 4 (exp_to_doc e)
    <-> nest 4 (text ")")
  | JUMP (e, ls) ->
    text "JUMP("
    <-> nest 5 (exp_to_doc e <-> comma)
    <-> nest 5 (concat (comma <-> line)
                  (List.map (fun l ->
                       text (Temp.label_to_string l)) ls))
    <-> nest 5 (text ")")
  | CJUMP (op, e0, e1, t, f) ->
    text "CJUMP("
    <-> nest 6 (
      (text (relop_to_string op) <-> comma)
      <-> line
      <-> (exp_to_doc e0) <-> comma
      <-> line
      <-> (exp_to_doc e1) <-> comma
      <-> line
      <-> (text (Temp.label_to_string t)) <-> comma
      <-> (text (Temp.label_to_string f))
      <-> text ")")
  | SEQ (s1, s2) ->
    text "SEQ("
    <-> nest 4 (stmt_to_doc s1 <-> comma
                <-> line
                <-> stmt_to_doc s2 <-> text ")")
  | LABEL (l) ->
    text (sprintf "LABEL(%s)" (Temp.label_to_string l))

let rec exp_to_string e =
  exp_to_doc e |> Pprint.layout

and stmt_to_string stmt =
  stmt_to_doc stmt |> Pprint.layout

(*let _ =
  CJUMP(GT, ESEQ( SEQ(EXP(CONST(0)), EXP(CONST(1))), CONST(1)), CONST(2), Temp.new_label(), Temp.new_label()) |> stmt_to_doc |> Pprint.print_doc;
  print_endline "---end---"*)
