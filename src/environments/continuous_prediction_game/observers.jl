using ...Observers.Modes: ModesObserver

function observe!(
    observer::ModesObserver, environment::ContinuousPredictionGameEnvironment
)
    if environment.entity_1.id < 0
        observer.to_observe_id = environment.entity_1.id
        observer.other_id = environment.entity_2.id
        observe!(observer, environment.entity_1)
    elseif environment.entity_2.id < 0
        observer.to_observe_id = environment.entity_2.id
        observer.other_id = environment.entity_1.id
        observe!(observer, environment.entity_2)
    else
        throw(ErrorException("Neither entity has a negative id for a ModesObserver."))
    end
end