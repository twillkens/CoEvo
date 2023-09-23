module Utilities

export StatFeatures, SpeciesStatReport, extract_features

using StatsBase: nquantile, skewness, kurtosis, mode
using HypothesisTests: OneSampleTTest, confint
using ....CoEvo.Abstract: Reporter, Report

Base.@kwdef struct StatFeatures
    sum::Float64 = 0.0
    upper_confidence::Float64 = 0.0
    mean::Float64 = 0.0
    lower_confidence::Float64 = 0.0
    variance::Float64 = 0.0
    std::Float64 = 0.0
    minimum::Float64 = 0.0
    lower_quartile::Float64 = 0.0
    median::Float64 = 0.0
    upper_quartile::Float64 = 0.0
    maximum::Float64 = 0.0
    skew::Float64 = 0.0
    kurt::Float64 = 0.0
    mod::Real = 0.0
end

function StatFeatures(metric::String, vec::Vector{<:Real}, n_round::Int=2)
    if isempty(vec)
        return StatFeatures(metric=metric, n_round=n_round)
    end

    quantiles = nquantile(vec, 4)
    loconf, hiconf = confint(OneSampleTTest(vec))

    # Use the round function on each feature to round to the specified number of digits
    return StatFeatures(
        sum=round(sum(vec), digits=n_round),
        lower_confidence=round(loconf, digits=n_round),
        mean=round(mean(vec), digits=n_round),
        upper_confidence=round(hiconf, digits=n_round),
        variance=round(var(vec), digits=n_round),
        std=round(std(vec), digits=n_round),
        minimum=round(quantiles[1], digits=n_round),
        lower_quartile=round(quantiles[2], digits=n_round),
        median=round(quantiles[3], digits=n_round),
        upper_quartile=round(quantiles[4], digits=n_round),
        maximum=round(quantiles[5], digits=n_round),
        skew=round(skewness(vec), digits=n_round),
        kurt=round(kurtosis(vec), digits=n_round),
        mod=round(mode(vec), digits=n_round),
    )
end

function StatFeatures(tup::Tuple{Vararg{<:Real}})
    StatFeatures(collect(tup))
end

function StatFeatures(vec::Vector{StatFeatures}, field::Symbol)
    StatFeatures([getfield(sf, field) for sf in vec])
end

function extract_features(sf::StatFeatures, features::Vector{Symbol})::Dict{String, Float64}
    feature_dict = Dict{String, Float64}()
    for feature in features
        val = getfield(sf, feature)
        if isa(val, Real)  # Ensure the value is a real number (Float64 or another subtype)
            feature_dict[string(feature)] = Float64(val)
        else
            throw(ArgumentError("Requested feature $feature is not a Real number in the StatFeatures object."))
        end
    end
    return feature_dict
end

struct SpeciesStatReport <: Report
    gen::Int
    species_id::String
    group_id::String
    metric::String
    stat_features::StatFeatures
end

end