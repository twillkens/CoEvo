export measure

function measure(metric::Metric, args...)
    throw(ErrorException("measure not implemented for metric: $metric with args: $args"))

end
