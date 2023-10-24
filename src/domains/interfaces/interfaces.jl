export measure

function measure(domain::Domain, args...)
    throw(ErrorException("`measure` not implemented for domain $(typeof(domain))"))
end
