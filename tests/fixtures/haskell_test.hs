{- Haskell file with nested {- -} block comments -}
calculate :: Int -> Int
calculate x =
    {- Multi-line block comment
       {- nested block comment -}
       spanning several lines -}
    let y = x * 2  -- inline comment

    -- standalone comment

    in y + 10  -- mixed: code + comment

{- EOF block comment -}
