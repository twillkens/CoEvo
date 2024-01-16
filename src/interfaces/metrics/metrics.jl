export measure

using ..Abstract

function measure(metric::Metric, args...)
    metric = typeof(metric)
    args = typeof(args)
    error("measure not implemented for $metric, $args")
end