function shufflesrv(x::Vector{String})
    for i in 1:length(x) - 1
        if x[i] == ""
            x[i] = x[i + 1]
            x[i + 1] = ""
        end
    end
    x
end

x = shufflesrv(["", "b", "c"])
println(x)