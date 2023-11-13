module Basic

export BasicArchiver

import ...Archivers: archive!

using DataStructures: OrderedDict
using HDF5: File, Group, h5open
using ...Individuals.Basic: BasicIndividual
using ...Species.Basic: BasicSpecies
using ...Metrics: Metric, Measurement, get_name
using ...Metrics.Common: RuntimeMetric, BasicMeasurement
using ...Metrics.Species: SnapshotSpeciesMetric, SnapshotSpeciesMeasurement
using ...Metrics.Species: StatisticalSpeciesMetric
using ...Reporters: Report
using ...Reporters.Basic: NullReport, BasicReport
using ..Archivers: Archiver, get_or_make_group!

include("archiver.jl")

include("measurements/measurements.jl")

include("fsms/fsms.jl")

include("genetic_programs/genetic_programs.jl")

include("gnarl_networks/gnarl_networks.jl")

include("vectors/vectors.jl")

include("function_graphs/function_graphs.jl")

end