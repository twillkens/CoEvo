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
    new_learner_population_records = evaluation.payoff_dodo_evaluation.records[
        1:ecosystem_creator.n_learner_population
    ]
    println("DISCO_RECORDS = ", [
        (record.rank, round(record.crowding; digits=3)) 
        for record in new_learner_population_records]
    )
    new_learner_population = [record.individual for record in new_learner_population_records]
    tournament_samples = [
        sample(new_learner_population_records, 5, replace = false) 
        for _ in 1:ecosystem_creator.n_learner_children
    ]
    learner_records = [
        run_tournament(samples, state.rng) for samples in tournament_samples
    ]
    println("SELECTED_LEARNER_RECORDS 00 = ", [
        (record.rank, round(record.crowding; digits=3)) 
        for record in learner_records]
    )   

    learner_parents = [record.individual for record in learner_records]
    new_learner_children = create_children(learner_parents, reproducer, state)
    return new_learner_population, new_learner_children
end

function update_learners_nu_disco(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)


    #rank_one_records = [record for record in evaluation.payoff_dodo_evaluation.records if record.rank == 1]
    #elites = sample(rank_one_records, 1)
    indivs = [record.individual for record in evaluation.payoff_dodo_evaluation.records]
    #elites = [record.individual for record in evaluation.payoff_dodo_evaluation.records[1:5]]

    #other_ids = farthest_first_traversal(evaluation.payoff_matrix, [elite.id for elite in elites], 5)
    #others = [indiv for indiv in indivs if indiv.id in other_ids]
    #for elite in [elites ; others]
    #        #elite = elite.individual
    #    filter!(learner -> learner != elite, ecosystem.learner_archive)
    #    push!(ecosystem.learner_archive, elite)
    #    if length(ecosystem.learner_archive) > 1000
    #    	popfirst!(ecosystem.learner_archive)
    #    end
    #end

    new_learner_population_records = evaluation.payoff_dodo_evaluation.records[
        1:ecosystem_creator.n_learner_population
    ]
    new_learner_population = [record.individual for record in new_learner_population_records]
    archive_sample_candidates = [
        learner for learner in ecosystem.learner_archive if !(learner in new_learner_population)
    ]
    n_archive_samples = min(length(archive_sample_candidates), 25)
    println("N_SAMPLES = ", n_archive_samples)
    archive_samples = sample(
        archive_sample_candidates, n_archive_samples, replace = false
    )
    n_archive_parents = min(length(archive_sample_candidates), 25)
    archive_parents = sample(
        archive_sample_candidates, n_archive_parents, replace = false
    )
    new_archive_children = create_children(archive_parents, reproducer, state; use_crossover = false)
    append!(archive_samples, new_archive_children)
    println("LEARNER_DISCO_RECORDS = ", [
        (record.rank, round(record.crowding; digits=3)) 
        for record in new_learner_population_records]
    )
    tournament_samples = [
        sample(new_learner_population_records, 5, replace = false) 
	for _ in 1:ecosystem_creator.n_learner_children - length(archive_samples)
    ]
    learner_records = [
        run_tournament(samples, state.rng) for samples in tournament_samples
    ]
    println("SELECTED_LEARNER_RECORDS = ", [
        (record.rank, round(record.crowding; digits=3)) 
        for record in learner_records]
    )   
    learner_parents = [record.individual for record in learner_records]
    #
    #n_learner_parents = ecosystem_creator.n_learner_children - length(archive_samples)
    #learner_parents = sample(
    #    new_learner_population, n_learner_parents, replace = true
    #)
    I = typeof(first(learner_parents))
    #append!(learner_parents, archive_samples)
    new_learner_children = create_children(learner_parents, reproducer, state; use_crossover = false)
    #append!(new_learner_children, archive_samples)
    #random_immigrants = create_children(
    #    sample(new_learner_children, 1, replace = true), reproducer, state; use_crossover = false
    #)
    #for immigrant in random_immigrants
    #    for i in eachindex(immigrant.genotype.genes)
    #        immigrant.genotype.genes[i] = rand(0:1)
    #    end
    #end
    #append!(new_learner_children, random_immigrants)
    #popfirst!(new_learner_children)
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
    n_sample_population = ecosystem_creator.n_learner_children
    id_scores = [
        learner => sum(evaluation.advanced_score_matrix[learner.id, :]) 
        for learner in new_learner_population
    ]
    println("id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    indices = roulette(state.rng, n_sample_population, [id_score[2] + 0.00001 for id_score in id_scores] )
    println("indices = ", indices)
    learner_parents = [first(id_score) for id_score in id_scores[indices]]
    new_learner_children = create_children(learner_parents, reproducer, state)
    return new_learner_population, new_learner_children
end

export update_learners_roulette

function update_learners_roulette(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    #new_learner_population = select_individuals_aggregate(
    #    ecosystem, evaluation.advanced_score_matrix, ecosystem_creator.n_learner_population
    #)
    new_learner_population = [ecosystem.learner_population ; ecosystem.learner_children]
    n_sample_population = ecosystem_creator.n_learner_population + ecosystem_creator.n_learner_children
    id_scores = [
        learner => sum(evaluation.advanced_score_matrix[learner.id, :]) 
        for learner in new_learner_population
    ]
    println("LEARNERS_id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    indices = roulette(state.rng, n_sample_population, [id_score[2] + 0.00001 for id_score in id_scores] )
    println("indices = ", indices)
    learner_parents = [first(id_score) for id_score in id_scores[indices]]
    new_learner_children = create_children(learner_parents, reproducer, state)
    new_learner_population, new_learner_children = new_learner_children[1:100],  new_learner_children[101:200]
    return new_learner_population, new_learner_children
end

export update_learners_control

function update_learners_control(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population = [ecosystem.learner_population ; ecosystem.learner_children]
    n_sample_population = ecosystem_creator.n_learner_population + ecosystem_creator.n_learner_children
    id_scores = [
        learner => sum(evaluation.advanced_score_matrix[learner.id, :]) 
        for learner in new_learner_population
    ]
    println("LEARNERS_id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    indices = rand(state.rng, 1:length(id_scores), n_sample_population)
    println("indices = ", indices)
    learner_parents = [first(id_score) for id_score in id_scores[indices]]
    new_learner_children = create_children(learner_parents, reproducer, state)
    new_learner_population, new_learner_children = new_learner_children[1:100], new_learner_children[101:200]
    return new_learner_population, new_learner_children
end

function update_learners_tourn(
    reproducer::Reproducer,
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem,
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population = select_individuals_aggregate(
        ecosystem, evaluation.advanced_score_matrix, ecosystem_creator.n_learner_population
    )
    n_sample_population = ecosystem_creator.n_learner_children
    id_scores = [
        learner => sum(evaluation.advanced_score_matrix[learner.id, :])
        for learner in new_learner_population
    ]
    println("LEARNER_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))

    # Tournament selection starts here
    tournament_size = 5  # This can be adjusted based on preference
    I = typeof(first(new_learner_population))
    learner_parents = I[]
    for _ in 1:n_sample_population
        tournament_contestants = rand(state.rng, id_scores, tournament_size)
        winner = reduce((x, y) -> x[2] > y[2] ? x : y, tournament_contestants)
        push!(learner_parents, winner[1])
    end
    # Tournament selection ends here

    #println("Selected parent indices for learners = ", [parent.id for parent in learner_parents])
    new_learner_children = create_children(learner_parents, reproducer, state)
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

# Function to perform Stochastic Universal Sampling
function stochastic_universal_sampling(evaluation_scores, population_size, rng)
    total_scores = sum(evaluation_scores)
    step_size = total_scores / population_size
    start_point = rand(rng) * step_size
    pointers = [start_point + i * step_size for i in 0:(population_size - 1)]

    selected_individuals = []
    cumulative_score = 0.0
    current_index = 1

    for pointer in pointers
        while cumulative_score < pointer
            cumulative_score += evaluation_scores[current_index]
            current_index += 1
        end
        push!(selected_individuals, current_index - 1)
    end

    return selected_individuals
end

# Function to calculate scores from an evaluation matrix for each individual
function calculate_individual_scores(evaluation_matrix, individuals)
    [sum(evaluation_matrix[individual, :]) for individual in individuals]
end

# Main function that updates learners using SUS
function update_learners_sus(
    reproducer::Reproducer,
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem,
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    # Assuming learners are indexed from 1 to n in the ecosystem
    all_scores = [sum(evaluation.advanced_score_matrix[i, :]) for i in evaluation.advanced_score_matrix.row_ids]
    learner_indices = stochastic_universal_sampling(all_scores, ecosystem_creator.n_learner_population, state.rng)
    println("LEARNER_INDICES = ", learner_indices)
    learner_ids = [evaluation.advanced_score_matrix.row_ids[i] for i in learner_indices]
    new_learner_population = [ecosystem[i] for i in learner_ids]

    parent_indices = stochastic_universal_sampling(all_scores, ecosystem_creator.n_learner_children, state.rng)
    parent_ids = [evaluation.advanced_score_matrix.row_ids[i] for i in learner_indices]
    learner_parents = [ecosystem[i] for i in parent_ids]
    new_learner_children = create_children(learner_parents, reproducer, state)

    return new_learner_population, new_learner_children
end

