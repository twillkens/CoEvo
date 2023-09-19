export FitnessLogger
export BasicGeneLogger
export StatFeatures
export SpeciesLogger
export make_group!


Base.@kwdef struct StatFeatures
    sum::Float64 = 0
    upper_confidence = 0
    mean::Float64 = 0
    lower_confidence = 0
    variance::Float64 = 0
    std::Float64 = 0
    minimum::Float64 = 0
    lower_quartile::Float64 = 0
    median::Float64 = 0
    upper_quartile::Float64 = 0
    maximum::Float64 = 0
end

function StatFeatures(vec::Vector{<:Real})
    if length(vec) == 0
        StatFeatures()
    else
        min_, lower_, med_, upper_, max_, = nquantile(vec, 4)
        loconf, hiconf = confint(OneSampleTTest(vec))
        StatFeatures(
            sum = sum(vec),
            lower_confidence = loconf,
            mean = mean(vec),
            upper_confidence = hiconf,
            variance = var(vec),
            std = std(vec),
            minimum = min_,
            lower_quartile = lower_,
            median = med_,
            upper_quartile = upper_,
            maximum = max_,
        )
    end
end

function StatFeatures(tup::Tuple{Vararg{<:Real}})
    StatFeatures(collect(tup))
end

function StatFeatures(vec::Vector{StatFeatures}, field::Symbol)
    StatFeatures([getfield(sf, field) for sf in vec])
end
