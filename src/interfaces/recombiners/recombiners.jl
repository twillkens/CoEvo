export recombine

using ..Abstract

function recombine(recombiner::Recombiner, individuals::Vector{Individual}, state::State)
    recombiner = typeof(recombiner)
    individuals = typeof(individuals)
    state = typeof(state)
    error("recombine not implemented for $recombiner, $individuals, $state")
end

function recombine(
    recombiner::Recombiner, 
    mutator::Mutator, 
    individuals::Vector{Individual}, 
    state::State
)
    recombiner = typeof(recombiner)
    mutator = typeof(mutator)
    individuals = typeof(individuals)
    state = typeof(state)
    error("recombine not implemented for $recombiner, $mutator, $individuals, $state")
end

function recombine(
    recombiner::Recombiner, 
    mutator::Mutator, 
    individuals::Vector{Vector{Individual}}, 
    state::State
)
    recombiner = typeof(recombiner)
    mutator = typeof(mutator)
    individuals = typeof(individuals)
    state = typeof(state)
    error("recombine not implemented for $recombiner, $mutator, $individuals, $state")
end

function recombine(
    recombiner::Recombiner, 
    individuals::Vector{Individual}, 
    reproducer::Reproducer,
    ::State
)
    recombiner = typeof(recombiner)
    individuals = typeof(individuals)
    reproducer = typeof(reproducer)
    error("recombine not implemented for $recombiner, $individuals, $reproducer")
end

function recombine(
    recombiner::Recombiner, 
    mutator::Mutator,
    individuals::Vector{Individual}, 
    reproducer::Reproducer,
    ::State
)
    recombiner = typeof(recombiner)
    mutator = typeof(mutator)
    individuals = typeof(individuals)
    reproducer = typeof(reproducer)
    error("recombine not implemented for $recombiner, $mutator, $individuals, $reproducer")
end

function recombine(
    recombiner::Recombiner, 
    mutator::Mutator,
    phenotype_creator::PhenotypeCreator,
    individuals::Vector{Individual},
    reproducer::Reproducer,
    ::State
)
    recombiner = typeof(recombiner)
    mutator = typeof(mutator)
    phenotype_creator = typeof(phenotype_creator)
    individuals = typeof(individuals)
    reproducer = typeof(reproducer)
    error("recombine not implemented for $recombiner, $mutator, $phenotype_creator, $individuals, $reproducer")
end

function recombine(
    recombiner::Recombiner, 
    mutator::Mutator,
    phenotype_creator::PhenotypeCreator,
    selections::Vector{Selection},
    reproducer::Reproducer,
    ::State
)
    recombiner = typeof(recombiner)
    mutator = typeof(mutator)
    phenotype_creator = typeof(phenotype_creator)
    individuals = typeof(selections)
    reproducer = typeof(reproducer)
    error("recombine not implemented for $recombiner, $mutator, $phenotype_creator, $individuals, $reproducer")
end