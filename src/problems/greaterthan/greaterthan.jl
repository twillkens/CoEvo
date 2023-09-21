module GreaterThan 

Base.@kwdef struct GreaterThanProblem <: Problem end


function interact(
    domain_id::Int, problem::GreaterThanProblem, obs_cfg::ObservationConfiguration,
    id1::Int, id2::Int, pheno1::Pheno{Vector{Float64}}, pheno2::Pheno{Vector{Float64}}
)
    subject.x.val = test.pheno[1]
    subject_y = eval(subject.expr)
    test_y = domain.func(test.pheno...)
    score = abs(test_y - subject_y)
    Outcome(oid, subject => score, test => -score, NullObs())
end


end