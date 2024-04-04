using ....Abstract

function run_tournament(contenders::Array{<:NewDodoRecord}, rng::AbstractRNG) 
    function get_winner(record_1::NewDodoRecord, record_2::NewDodoRecord)
        if record_1.rank < record_2.rank
            return record_1
        elseif record_2.rank < record_1.rank
            return record_2
        else
            if record_1.crowding > record_2.crowding
                return record_1
            elseif record_2.crowding > record_1.crowding
                return record_2
            else
                return rand(rng, (record_1, record_2))
            end
        end
    end
    winner = reduce(get_winner, contenders)
    return winner
end

function update_learners_disco(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population_records = evaluation.payoff_dodo_evaluation.records[1:ecosystem_creator.n_learner_population]
    println("DISCO_RECORDS = ", [(record.rank, round(record.crowding; digits=3)) for record in new_learner_population_records])
    new_learner_population = [record.individual for record in new_learner_population_records]
    tournament_samples = [sample(new_learner_population_records, 3, replace = false) for _ in 1:ecosystem_creator.n_learner_children]
    learner_parents = [run_tournament(samples, state.rng).individual for samples in tournament_samples]
    #append!(learner_parents, ecosystem.learner_archive)
    new_learner_children = create_children(learner_parents, reproducer, state)
    return new_learner_population, new_learner_children
end

function update_learners(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population = select_individuals_aggregate(
        ecosystem, evaluation.advanced_score_matrix, ecosystem_creator.n_learner_population
    )
    #n_sample_archive = min(length(ecosystem.learner_archive), 10)
    #n_sample_population = 40 - n_sample_archive # ecosystem_creator.n_learner_children
    n_sample_population = ecosystem_creator.n_learner_children
    id_scores = [
        learner => sum(evaluation.advanced_score_matrix[learner.id, :]) 
        for learner in new_learner_population
    ]
    println("id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    indices = roulette(state.rng, n_sample_population, [id_score[2] + 0.00001 for id_score in id_scores] )
    println("indices = ", indices)
    learner_parents = [first(id_score) for id_score in id_scores[indices]]
    #archive_parents = sample(
    #    ecosystem.learner_archive, n_sample_archive, replace = true
    #)
    #new_archive_children = create_children(archive_parents, reproducer, state)
    #learner_parents = sample(
    #    new_learner_population, n_sample_population, replace = true
    #)
    append!(learner_parents, ecosystem.learner_archive)
    new_learner_children = create_children(learner_parents, reproducer, state)
    #I = typeof(first(new_learner_population))
    #return I[], [new_archive_children ; new_learner_children]
    return new_learner_population, new_learner_children
end

function update_learners_no_elites(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population = select_individuals_aggregate(
        ecosystem, evaluation.learner_score_matrix, ecosystem_creator.n_learner_population
    )
    #n_sample_archive = min(length(ecosystem.learner_archive), 10)
    n_sample_archive = length(ecosystem.learner_archive)
    archive_parents = sample(
        ecosystem.learner_archive, n_sample_archive, replace = true
    )
    new_archive_children = create_children(archive_parents, reproducer, state)
    n_sample_population = ecosystem_creator.n_learner_children + ecosystem_creator.n_learner_population - n_sample_archive
    learner_parents = sample(
        new_learner_population, n_sample_population, replace = true
    )
    new_learner_children = create_children(learner_parents, reproducer, state)
    I = typeof(first(new_learner_population))
    return I[], [new_archive_children ; new_learner_children]
    #return new_learner_population, new_learner_children
end

function update_learners_regularized(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population = copy(ecosystem.learner_population)
    append!(new_learner_population, ecosystem.learner_children)
    #push!(new_learner_population, first(ecosystem.learner_children))
    I = typeof(first(new_learner_population))
    parents = I[]
    for _ in 1:5
        competitors = sample(new_learner_population, 3, replace = false)
        id_scores = [
            learner => sum(evaluation.learner_score_matrix[learner.id, :]) 
            for learner in competitors
        ]
        parent = first(reduce(
            (id_score_1, id_score_2) -> id_score_1[2] > id_score_2[2] ? 
            id_score_1 : id_score_2, 
            id_scores
        ))
        push!(parents, parent)
    end
    new_learner_children = create_children(parents, reproducer, state)
    for _ in 1:5
        popfirst!(new_learner_population)
    end
    #I = typeof(first(new_learner_population))
    #return I[], [new_archive_children ; new_learner_children]
    if length(ecosystem.learner_population) != length(new_learner_population)
        error("length(ecosystem.learner_population) = $(length(ecosystem.learner_population)), length(new_learner_population) = $(length(new_learner_population))")
    end
    return new_learner_population, new_learner_children
end