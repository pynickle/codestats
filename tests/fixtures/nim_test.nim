# Nim file with nested block comments
proc calculate(x: int): int =
  #[ Nested block comment
     #[ inner comment ]#
     spanning lines ]#
  let y = x * 2  # inline comment

  # standalone comment

  result = y + 10  # mixed: code + comment

#[ EOF block comment ]#
