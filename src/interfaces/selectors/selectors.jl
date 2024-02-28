export select

using ..Abstract

function select(selector::Selector, records::Vector{<:Record}, state::State)
    selector = typeof(selector)
    records = typeof(records)
    state = typeof(state)
    error("select not implemented for $selector, $records, $state")
end


function select(selector::Selector, records::Vector{<:Record}, n_selections::Int, state::State)
    selector = typeof(selector)
    records = typeof(records)
    n_selections = typeof(n_selections)
    state = typeof(state)
    error("select not implemented for $selector, $records, $n_selections, $state")
end