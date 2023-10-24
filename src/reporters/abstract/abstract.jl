export Report, Reporter

abstract type Report{MET <: Metric, MEA <: Measurement} end

abstract type Reporter{M <: Metric} end
