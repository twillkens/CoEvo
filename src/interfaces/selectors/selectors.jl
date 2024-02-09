export select

using ..Abstract

function select(selector::Selector, records::Vector{<:Record}, state::State)
    selector = typeof(selector)
    records = typeof(records)
    state = typeof(state)
    error("select not implemented for $selector, $records, $state")
end