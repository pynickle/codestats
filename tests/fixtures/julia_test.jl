# Julia file with #= =# block comments
function calculate(x)
    #= Multi-line block comment
       spanning several lines
       with nested math =#
    y = x * 2  # inline comment

    # standalone comment

    return y + 10  # mixed: code + comment
end

#= EOF block comment =#
