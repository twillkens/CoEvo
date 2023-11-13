export measure, get_name, aggregate

function measure(metric::Metric, args...)
    throw(ErrorException("measure not implemented for metric: $metric with args: $args"))
end

function get_name(metric::Metric)
    return metric.name
end

function aggregate(aggregator::Aggregator, measurements::Vector{Measurement})
    throw(ErrorException(
        "`aggregate` not implemented for aggregator: $aggregator with measurements: $measurements"
    ))
end