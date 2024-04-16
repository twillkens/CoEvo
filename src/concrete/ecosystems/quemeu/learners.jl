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
    evaluation::QueMEUEvaluation,
    ecosystem::QueMEUEcosystem, 
    ecosystem_creator::QueMEUEcosystemCreator,
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
    println("SELECTED_LEARNER_RECORDS = ", [
        (record.rank, round(record.crowding; digits=3)) 
        for record in learner_records]
    )   

    learner_parents = [record.individual for record in learner_records]
    new_learner_children = create_children(learner_parents, reproducer, state)
    return new_learner_population, new_learner_children
end


