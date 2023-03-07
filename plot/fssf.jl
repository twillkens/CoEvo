export FSMSpeciesSizeFeatures

struct FSMSpeciesSizeFeatures
    genosf::StatFeatures
    mingenosf::StatFeatures
end

function FSMSpeciesSizeFeatures(genovec::Vector{Int}, mingenovec::Vector{Int})
    FSMSpeciesSizeFeatures(StatFeatures(genovec), StatFeatures(mingenovec))
end

function FSMSpeciesSizeFeatures(igroup::JLD2.Group)
    allsizes = Vector{Int}()
    allminsizes = Vector{Int}()
    for child in values(sp.children)
        push!(allsizes, length(igroup["geno"].ones) + length(igroup["geno"].zeros))
        push!(allminsizes, length(child.mingeno.ones) + length(child.mingeno.zeros))
    end
    FSMSpeciesSizeFeatures(StatFeatures(allsizes), StatFeatures(allminsizes))
end

function FSMSpeciesSizeFeatures(sp::Species)
    allsizes = Vector{Int}()
    allminsizes = Vector{Int}()
    for child in values(sp.children)
        push!(allsizes, length(child.geno.ones) + length(child.geno.zeros))
        push!(allminsizes, length(child.mingeno.ones) + length(child.mingeno.zeros))
    end
    FSMSpeciesSizeFeatures(StatFeatures(allsizes), StatFeatures(allminsizes))
end

function FSMSpeciesSizeFeatures(v::Vector{FSMSpeciesSizeFeatures}, field::Symbol)
    FSMSpeciesSizeFeatures(
        StatFeatures([v.genosf for v in v], field),
        StatFeatures([v.mingenosf for v in v], field)
    )
end