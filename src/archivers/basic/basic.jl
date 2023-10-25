module Basic

export BasicArchiver

import ...Archivers: archive!, save_genotype!, save_measurement!

using DataStructures: OrderedDict
using JLD2: JLDFile, Group, jldopen
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

include("savers/savers.jl")


end