function default_geno(;key::String = "AllZeros",
                        width::Int = 10,
                        default_val::Bool = false)
    cfg = DefaultBitstringConfig(width=width, default_val=default_val)
    cfg(key)
end

function make_genocfg(::Type{DefaultBitstringConfig}; width=10, default_val=false, kwargs...)
    DefaultBitstringConfig(width=width, default_val=default_val)
end

function make_genocfg(::Type{RandomBitstringConfig}; width=10, rng=StableRNG(123), kwargs...)
    RandomBitstringConfig(width=width, rng=rng)
end

function make_phenocfg(::Type{IntPhenoConfig}, popkey::String; kwargs...)
    IntPhenoConfig()
end

function make_phenocfg(::Type{VectorPhenoConfig}, popkey::String; subvector_width=10, kwargs...)
    VectorPhenoConfig(subvector_width=subvector_width)
end

function make_genotype(key::String, T::Type{<:GenoConfig}; kwargs...)
    cfg = make_genocfg(T; kwargs...)
    cfg(key, cfg)
end

function make_phenotype(key::String,
                        G::Type{<:GenoConfig},
                        P::Type{<:PhenoConfig};
                        kwargs...)
    pheno_cfg = make_phenocfg(P, key; kwargs...)
    geno = make_genotype(key, G; kwargs...)
    pheno_cfg(geno)
end

function make_testpop(;geno_cfg_T::Type{<:GenoConfig} = DefaultBitstringConfig,
                        key::String = "A",
                        n_genos::Int = 10,
                        kwargs...)
    geno_cfg = make_genocfg(geno_cfg_T; kwargs...)
    pop_cfg = GenoPopConfig(key = key, n_genos = n_genos, geno_cfg = geno_cfg)
    (pop_cfg)()
end


function make_allvsall_order(;subjects_popkey::String = "A",
                            tests_popkey::String = "B",
                            subjects_phenocfg_T::Type{<:PhenoConfig} = IntPhenoConfig,
                            tests_phenocfg_T::Type{<:PhenoConfig} = IntPhenoConfig,
                            ng_domain_T::Type{<:NumbersGame} = NGGradient,
                            outcome_T::Type{<:Outcome} = TestPairOutcome,
                            kwargs...)

    domain = ng_domain_T()
    subjects_phenocfg = make_phenocfg(subjects_phenocfg_T, subjects_popkey; kwargs...)
    tests_phenocfg = make_phenocfg(tests_phenocfg_T, tests_popkey; kwargs...)
    AllvsAllOrder(domain, outcome_T, subjects_phenocfg, tests_phenocfg,)
end

function make_sampler_order(;subjects_popkey::String = "A",
                            tests_popkey::String = "B",
                            rng::AbstractRNG = StableRNG(123),
                            n_samples=5,
                            subjects_phenocfg_T::Type{<:PhenoConfig} = IntPhenoConfig,
                            tests_phenocfg_T::Type{<:PhenoConfig} = IntPhenoConfig,
                            ng_domain_T::Type{<:NumbersGame} = NGGradient,
                            outcome_T::Type{<:Outcome} = TestPairOutcome,
                            kwargs...)
    domain = ng_domain_T()
    
    subjects_phenocfg = make_phenocfg(subjects_phenocfg_T, subjects_popkey; kwargs...)
    tests_phenocfg = make_phenocfg(tests_phenocfg_T, tests_popkey; kwargs...)
    SamplerOrder(domain=domain, outcome=outcome_T, subjects_phenocfg, tests_phenocfg; kwargs...)
end

function default_job(;kwargs...)
    popA = make_testpop(;key = "A", kwargs...)
    popB = make_testpop(;key = "B", default_val = true, kwargs...)
    pops = Set([popA, popB])
    order = make_sampler_order(;subjects_popkey = "A", tests_popkey = "B", kwargs...)
    orders = Set([order])
    cfg = SerialJobConfig()
    cfg(orders, pops)
end

function default_jobs(;kwargs...)
    popA = make_testpop(;key = "A", kwargs...)
    popB = make_testpop(;key = "B", default_val = true, kwargs...)
    pops = Set([popA, popB])
    orderA = make_sampler_order(;subjects_popkey = "A", tests_popkey = "B", kwargs...)
    orderB = make_sampler_order(;subjects_popkey = "B", tests_popkey = "A", kwargs...)
    orders = Set([orderA, orderB])
    cfg = SerialJobConfig()
    cfg(orders, pops)
end


function default_coev(; rng=StableRNG(123), kwargs...)
    geno_cfg = DefaultBitstringConfig()

    popA = make_testpop(;rng=rng, key = "A", n_genos=25, kwargs...)
    popB = make_testpop(;rng=rng, key = "B", n_genos=25, default_val = true, kwargs...)

    pops = Set([popA, popB])
    orderA = make_sampler_order(;rng=rng, subjects_popkey = "A", tests_popkey = "B", kwargs...)
    orderB = make_sampler_order(;rng=rng, subjects_popkey = "B", tests_popkey = "A", kwargs...)
    orders = Set([orderA, orderB])
    selector = RouletteSelector(; key="A", rng=rng,)
    selectors = Set()


end
