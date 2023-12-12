export ModesReporter, update_species_list!

export ModesReporter, update_species_list!

using ...Metrics: Metric, Measurement
using ...Metrics.Common: BasicMeasurement
using ...Metrics.Modes: ModesMetric
using ...Metrics.Modes: MaximumComplexityMetric, ModesNoveltyMetric, ModesChangeMetric
using ...Species: AbstractSpecies
using ...Genotypes: Genotype
using ...Reporters: Reporter    

Base.@kwdef struct ModesReporter{S <: AbstractSpecies, G <: Genotype} <: Reporter
    metric::Metric = ModesMetric()
    complexity_metric::Metric = MaximumComplexityMetric("modes/complexity")
    novelty_metric::Metric = ModesNoveltyMetric("modes/novelty")
    change_metric::Metric = ModesChangeMetric("modes/change")
    modes_interval::Int = 50
    to_print::Bool = true
    to_save::Bool = true
    tag_dictionary::Dict{Int, Int} = Dict{Int, Int}()
    persistent_ids::Set{Int} = Set{Int}()
    all_species::Vector{S} = S[]
    previous_modes_genotypes::Set{G} = Set{G}()
    all_modes_genotypes::Set{G} = Set{G}()
end

function update_species_list!(reporter::ModesReporter, all_species::Vector{<:AbstractSpecies})
    empty!(reporter.all_species)
    for species in all_species
        push!(reporter.all_species, species)
    end
end
