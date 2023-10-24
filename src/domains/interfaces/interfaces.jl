module Interfaces

export measure

using ..Domains.Abstract: Domain

function measure(domain::Domain, args...)
    throw(ErrorException("`measure` not implemented for domain $(typeof(domain))"))
end

end