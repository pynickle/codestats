-- Ada Test File
with Ada.Text_IO;

procedure Ada_Test is
   -- This is a comment in Ada
   Count : Integer := 0;
begin
   -- Print a message
   Ada.Text_IO.Put_Line("Hello from Ada!");

   Count := Count + 1;

   -- Display count
   Ada.Text_IO.Put_Line("Count:" & Integer'Image(Count));
end Ada_Test;
