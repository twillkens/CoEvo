import ...Observers: observe!
using ...Observers.Modes: PhenotypeStateObserver

function observe!(
    observer::PhenotypeStateObserver, environment::ContinuousPredictionGameEnvironment
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
        throw(ErrorException("Neither entity has a negative id for a PhenotypeStateObserver."))
    end
end