module Interfaces

export measure

using ..Metrics.Abstract: Metric

function measure(metric::Metric, args...)
    throw(ErrorException("measure not implemented for metric: $metric with args: $args"))

end

end