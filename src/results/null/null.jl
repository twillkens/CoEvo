module Null

export NullResult

using ...Results: Result

struct NullResult <: Result end

end