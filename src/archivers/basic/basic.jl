module Basic

export BasicArchiver

import ...Archivers: archive!, save_genotype!, save_measurement!

using DataStructures: OrderedDict
using HDF5: File, Group, h5open
using ...Individuals: Individual
using ...Metrics: Metric
using ...Metrics.Common: AllSpeciesIdentity
using ...Metrics.Evaluations: AllSpeciesFitness, AbsoluteError
using ...Metrics.Genotypes: GenotypeSum, GenotypeSize
using ...Measurements.Statistical: GroupStatisticalMeasurement, BasicStatisticalMeasurement
using ...Measurements.Common: AllSpeciesMeasurement
using ...Reporters: Report
using ...Reporters.Basic: BasicReport
using ...Reporters.Runtime: RuntimeReport
using ..Archivers: Archiver, get_or_make_group!

include("archiver.jl")

include("measurements/measurements.jl")

include("fsms/fsms.jl")

include("genetic_programs/genetic_programs.jl")

include("gnarl_networks/gnarl_networks.jl")

include("vectors/vectors.jl")

include("function_graphs/function_graphs.jl")

end