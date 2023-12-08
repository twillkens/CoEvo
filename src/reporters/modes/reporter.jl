export ModesReporter, update_species_list!

export ModesReporter, update_species_list!

using ...Metrics: Metric, Measurement
using ...Metrics.Common: BasicMeasurement
using ...Metrics.Modes: ModesMetric
using ...Metrics.Modes: MaximumComplexityMetric, ModesNoveltyMetric, ModesChangeMetric
using ...Species: AbstractSpecies
using ...Genotypes: Genotype
using ...Reporters: Reporter    

Base.@kwdef mutable struct ModesReporter{S <: AbstractSpecies} <: Reporter
    metric::Metric = ModesMetric()
    complexity_metric::Metric = MaximumComplexityMetric("modes/complexity")
    novelty_metric::Metric = ModesNoveltyMetric("modes/novelty")
    change_metric::Metric = ModesChangeMetric("modes/change")
    modes_interval::Int = 10
    tag_dictionary::Dict{Int, Int} = Dict{Int, Int}()
    persistent_ids::Set{Int} = Set{Int}()
    all_species::Vector{S} = AbstractSpecies[]
    previous_modes_generation::Int = 0
    previous_modes_genotypes::Set{Genotype} = Set{Genotype}()
    all_modes_genotypes::Set{Genotype} = Set{Genotype}()
end

function update_species_list!(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    reporter.all_species = copy(all_species)
end
