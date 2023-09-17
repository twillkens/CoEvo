
struct SymbolicRegression <: Domain
    points::Vector{Float64}
    func::Function
end

function stir(
    oid::Symbol, domain::SymbolicRegression, obscfg::ObsConfig,
    pheno1::FSMPheno, pheno2::FSMPheno
)
    loopstart, states1, states2, traj1, traj2 = simulate(domain, pheno1, pheno2)
    score = 1
    obs = obscfg(loopstart, pheno1, pheno2, states1, states2, traj1, traj2)
    Outcome(oid, pheno1 => score, pheno2 => score, obs)
end