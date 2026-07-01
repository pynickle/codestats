{ Pascal file with dual block comments }
program Calculate;

var
  x, y: Integer;

begin
  { Curly brace block comment
    spanning multiple lines }
  x := 42;  { inline comment }

  (* Parenthesis-star block comment
     also spanning lines *)

  y := x * 2;  (* mixed: code + comment *)

end.
