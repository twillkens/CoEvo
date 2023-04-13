using Serialization
using CSV
using Pingouin
using HypothesisTests

function change2()
    ctrl = deserialize("modesdata/ctrl-ko-40.jls")
    comp = deserialize("modesdata/comp-ko-40.jls")
    coop = deserialize("modesdata/coop-ko-40.jls")
    change = DataFrame(Dict(
        "ctrl-hop" => ctrl[!, "min-change-mean"],
        "comp-hop" => comp[!, "min-change-mean"],
        "comp-ko" => comp[!, "modes-change-mean"],
        "coop-hop" => coop[!, "min-change-mean"],
        "coop-ko" => coop[!, "modes-change-mean"],
    ))
    KruskalWallisTest(collect(eachcol(change))...)
end