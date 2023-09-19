using CoEvo.Base.Reproduction
using CoEvo.Base.Indivs.GP
using CoEvo.Base.Indivs.GP: GPPheno, GPPhenoCfg
using CoEvo.Base.Indivs.GP: GPGeno, ExprNode, Terminal, GPMutator, FuncAlias
using CoEvo.Base.Indivs.GP: GPGenoCfg, GPGenoArchiver
using CoEvo.Base.Indivs.GP: get_node, get_child_index, get_ancestors, get_descendents
using CoEvo.Base.Indivs.GP: addfunc, rmfunc, swapnode, inject_noise, splicefunc
using CoEvo.Base.Indivs.GP: pdiv, iflt, psin

using CoEvo.Domains.SymRegression
using CoEvo.Domains.SymRegression: stir
using CoEvo.Base.Jobs
using CoEvo.Domains.ContinuousPredictionGame


using CoEvo.Base.Reproduction: get_clusters


function evolve!(; do_parallel::Bool = true)
    eco = :continuous_prediction_game
    trial = 1
    seed = 420
    npop = 50
    episode_len = 32
    njobs = 5
    terms = Dict{Terminal, Int}(:read => 1, 0.0 => 1)
    funcs = Dict{FuncAlias, Int}([
        (+, 2), 
        (-, 2), 
        (*, 2), 
        (pdiv, 2), 
        (psin, 1),
        (iflt, 4),
    ])
    mutator = GPMutator(terminals = terms, functions = funcs)

    function make_spawner(spid::Symbol)
        Spawner(
            spid = spid,
            npop = npop,
            genocfg = GPGenoCfg(),
            phenocfg = GPPhenoCfg(),
            replacer = DiscoReplacer(),
            selector = NSGASelector(),
            recombiner = CloneRecombiner(),
            mutators = [mutator],
        )
    end
    
    orders = [
        AllvsAllPlusOrder(
            oid = :host_para, 
            spids = [:host, :para], 
            domain = ContinuousPredictionGameDomain(
                episode_len = episode_len,
                type = "comp",
            ),
            obscfg = NullObsConfig(),
        ),
        AllvsAllPlusOrder(
            oid = :host_mut, 
            spids = [:host, :mut], 
            domain = ContinuousPredictionGameDomain(
                episode_len = episode_len,
                type = "coop_match",
            ),
            obscfg = NullObsConfig(),
        ),
    ]


    host_spawner = make_spawner(:host)
    para_spawner = make_spawner(:para)
    mut_spawner = make_spawner(:mut)
    coev_cfg = CoevConfig(
        eco = eco,
        trial = trial,
        seed = seed,
        orders = orders,
        spawners = [host_spawner, para_spawner, mut_spawner],
        jobcfg = do_parallel ? ParallelPhenoJobConfig(njobs = njobs) : SerialPhenoJobConfig(),
        arxiv_interval = 0,
        log_interval = 1,
    )
    species = coev_cfg()
    evolve!(1, 5_000, coev_cfg, species)
end
