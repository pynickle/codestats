// F# file with // and (* *) block comments
let calculate x =
    (* Multi-line block comment
       spanning several lines
       with calculations *)
    let y = x * 2  // inline comment

    // standalone comment

    y + 10  // mixed: code + comment

(* EOF block comment *)
