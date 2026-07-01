(* OCaml file with (* *) block comments *)
let calculate x =
    (* Multi-line block comment
       spanning several lines
       with calculations *)
    let y = x * 2 in  (* inline comment *)

    (* standalone comment *)

    y + 10  (* mixed: code + comment *)

(* EOF block comment *)
