export measure
using ..Abstract


function measure(domain::Domain, args...)
    throw(ErrorException("`measure` not implemented for domain $(typeof(domain))"))
end