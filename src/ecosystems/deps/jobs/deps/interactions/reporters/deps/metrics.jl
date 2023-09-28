module Metrics

using .Abstract: DomainMetric

struct TheTwoVectorsWithGreatestSineOfSums <: Metric end
struct TheVectorWithAverageClosestToPi <: Metric end
end