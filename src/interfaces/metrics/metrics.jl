export measure, get_name, aggregate

using ..Abstract

function measure(metric::Metric, args...)
    throw(ErrorException("measure not implemented for metric: $metric with args: $(typeof(args))"))
end

function get_name(metric::Metric)
    return metric.name
end

function aggregate(aggregator::Aggregator, measurements::Vector{Measurement})
    throw(ErrorException(
        "`aggregate` not implemented for aggregator: $aggregator with measurements: $measurements"
    ))
end