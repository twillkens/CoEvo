
"Recombination"


function adjcrosstree(t1::Expr, t2::Expr, rng::AbstractRNG)
    fcounts_t1 = [get_nfuncs(t1[i]) for i in 1:(length(t1) - 1)]
    fcounts_t2 = [get_nfuncs(t2[i]) for i in 1:(length(t2) - 1)]
    valid = Tuple{Int, Int}[]
    for (i, count1) in enumerate(fcounts_t1)
        for (j, count2) in enumerate(fcounts_t2)
            if abs(count2 - count1) < 2
                if !(count1 == 0 && count2 == 0 && t1[i] == t2[j])
                    push!(valid, (i, j))
                end
            end
        end
    end

    tt1, tt2 = copy(t1), copy(t2)
    i, j = rand(rng, valid)
    ex1 = tt1[i]
    ex2 = tt2[j]
    tt1[i] = ex2
    tt2[j] = ex1
    if abs(get_nfuncs(tt1) - get_nfuncs(t1)) < 2 &&
        abs(get_nfuncs(tt2) - get_nfuncs(t2)) < 2 
        tt1, tt2, valid
    else
        throw(InvalidStateException("bad", :fuck))
    end
end

function crosstree(t1::Expr, t2::Expr; rng::AbstractRNG=default_rng())
    tt1, tt2 = copy(t1), copy(t2)
    i, j = Base.rand(rng, 1:nodes(t1)-1), Base.rand(rng, 1:nodes(t2)-1)
    ex1 = tt1[i]
    ex2 = tt2[j]
    tt1[i] = ex2
    tt2[j] = ex1
    tt1, tt2
end