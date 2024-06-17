export update_learners_p_phc, update_learners_p_phc_p_frs, update_learners_p_phc_p_uhs
export update_learners, update_learners_roulette, update_learners_control, update_learners_tourn
export update_learners_sus

using ....Abstract
using ...Evaluators.NSGAII: dominates 

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


function update_learners_p_phc(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_population = copy(ecosystem.learner_population)
    for parent in ecosystem.learner_population
        children = [child for child in ecosystem.learner_children if child.parent_id == parent.id]
        if length(children) != 1
            error("length(children) = $(length(children))")
        end
        child = first(children)
        parent_outcomes = evaluation.payoff_matrix[parent.id, :]
        child_outcomes = evaluation.payoff_matrix[child.id, :]
        child_dominates_parent = dominates(child_outcomes, parent_outcomes)
        if child_dominates_parent
            new_population = [indiv for indiv in new_population if indiv != parent]
            push!(new_population, child)
        end
    end
    new_children = create_children(new_population, reproducer, state)
    return new_population, new_children
end

function update_learners_p_phc_p_frs(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_population = copy(ecosystem.learner_population)
    for parent in ecosystem.learner_population
        children = [child for child in ecosystem.learner_children if child.parent_id == parent.id]
        if length(children) != 1
            error("length(children) = $(length(children))")
        end
        child = first(children)
        parent_outcomes = evaluation.payoff_matrix[parent.id, :]
        child_outcomes = evaluation.payoff_matrix[child.id, :]
        parent_dominates_child = dominates(parent_outcomes, child_outcomes)
        if !parent_dominates_child
            new_population = [indiv for indiv in new_population if indiv != parent]
            push!(new_population, child)
        end
    end
    new_children = create_children(new_population, reproducer, state)
    return new_population, new_children
end

function update_learners_p_phc_p_uhs(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_population = copy(ecosystem.learner_population)
    for parent in ecosystem.learner_population
        children = [child for child in ecosystem.learner_children if child.parent_id == parent.id]
        if length(children) != 1
            error("length(children) = $(length(children))")
        end
        child = first(children)
        parent_outcomes = evaluation.payoff_matrix[parent.id, :]
        child_outcomes = evaluation.payoff_matrix[child.id, :]
        parent_dominates_child = dominates(parent_outcomes, child_outcomes)
        child_at_same_or_higher_level = sum(child_outcomes) >= sum(parent_outcomes)
        if !parent_dominates_child && child_at_same_or_higher_level
            new_population = [indiv for indiv in new_population if indiv != parent]
            push!(new_population, child)
        end
    end
    new_children = create_children(new_population, reproducer, state)
    return new_population, new_children
end

function update_learners_doc(
    reproducer::Reproducer, 
    evaluation::MaxSolveEvaluation,
    ecosystem::MaxSolveEcosystem, 
    ecosystem_creator::MaxSolveEcosystemCreator,
    state::State
)
    new_learner_population_records = evaluation.payoff_dodo_evaluation.records[
        1:ecosystem_creator.n_learner_population
    ]
    #println("DISCO_RECORDS = ", [
    #    (record.rank, round(record.crowding; digits=3)) 
    #    for record in new_learner_population_records]
    #)
    new_learner_population = [record.individual for record in new_learner_population_records]
    tournament_samples = [
        sample(new_learner_population_records, 5, replace = false) 
        for _ in 1:ecosystem_creator.n_learner_children
    ]
    learner_records = [
        run_tournament(samples, state.rng) for samples in tournament_samples
    ]
    #println("SELECTED_LEARNER_RECORDS 00 = ", [
    #    (record.rank, round(record.crowding; digits=3)) 
    #    for record in learner_records]
    #)   

    learner_parents = [record.individual for record in learner_records]
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
    #println("LEARNERS_id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    indices = roulette(state.rng, n_sample_population, [id_score[2] + 0.00001 for id_score in id_scores] )
    #println("indices = ", indices)
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
    #println("LEARNERS_id_scores = ", round.([id_score[2] for id_score in id_scores]; digits = 3))
    indices = rand(state.rng, 1:length(id_scores), n_sample_population)
    #println("indices = ", indices)
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

