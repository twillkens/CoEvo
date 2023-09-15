using CoEvo
using JLD2
using Graphs
using GraphRecipes
using Plots
using Colors

function get_sequential_pairs(v::Vector, other_outs::Vector{Bool})
    return collect(zip(v[1:end-1], v[2:end], other_outs))
end

# function plot_geno(geno::FSMGeno, currstate::Real, seen::Vector{<:Real}, other_outs::Vector{Bool})
#     # First, we create a list of all unique states in the genotype
#     
#     unique_states = sort(collect(union(geno.ones, geno.zeros)))
#     edges_seen = get_sequential_pairs(seen, other_outs)
#     # Then, we create a mapping from each state to a unique integer (since adjacency matrix uses integer indices)
#     state_indices = Dict(state => idx for (idx, state) in enumerate(unique_states))
#     
#     # Now, we create an adjacency matrix for our graph with zeros
#     g = [[] for _ in 1:length(unique_states)]
#     edgecolor = Dict()
#     lightgreen = colormap("Greens", 100)[20]
#     lightred = colormap("Reds", 100)[20]
# 
#     # We set values in the matrix to 1 for each link in the genotype
#     for ((from_state, input), to_state) in geno.links
#         from_idx = state_indices[from_state]
#         to_idx = state_indices[to_state]
#         push!(g[from_idx], to_idx)
#         #if geno.links[(from_state, true)] == geno.links[(from_state, false)]
#         #    edgecolor[from_idx, to_idx] = colorant"purple"
#         #else
#             if (from_state, to_state, input) ∈ edges_seen 
#                 edgecolor[(from_idx, to_idx, Int(input) + 1)] = input ? colorant"green" : colorant"red"
#             else
#                 edgecolor[(from_idx, to_idx, Int(input) + 1)] = input ? lightgreen : lightred
#             end
#         #end
#     end
# 
#     # Now, we create a color map for the nodes in the graph
#     nodecolor = fill(colorant"#CCCCCC", length(unique_states))  # Default gray color
#     nodeshape = fill(:circle, length(unique_states))  # Default gray color
#     nodeshape[state_indices[geno.start]] = :rect
# 
#     # We color the ones-states in red
#     for one_state in geno.ones
#         nodecolor[state_indices[one_state]] = one_state ∈ seen ? colorant"green" : lightgreen
#     end
# 
#     # We color the zero-states in purple (or any other desired color)
#     for zero_state in geno.zeros
#         nodecolor[state_indices[zero_state]] = zero_state ∈ seen ? colorant"red" : lightred
#     end
#     if currstate != 0
#         nodecolor[state_indices[currstate]] = colorant"orange"
#     end
#     # Finally, we plot the graph using GraphRecipes
#     println(g)
#     println(edgecolor)
#     graphplot(
#         g,
#         names=1:length(unique_states),
#         curves=true,
#         color=:black,
#         nodecolor=nodecolor,
#         edgecolor=edgecolor,
#         method=:shell,
#         nodeshape=nodeshape,
#         self_edge_size=0.25,
#     )
# end

function plot_geno(
    geno::FSMGeno, 
    currstate::Real,
    seen::Vector{<:Real}; 
    do_labels::Bool = false, 
    self_edge_size::Float64 = 0.15, 
    fontsize::Int = 12, 
    title::String="", 
    kwargs...
)
    # First, we create a list of all unique states in the genotype
    unique_states = sort(collect(union(geno.ones, geno.zeros)))
    edges_seen = get_sequential_pairs(seen)
    # Then, we create a mapping from each state to a unique integer (since adjacency matrix uses integer indices)
    state_indices = Dict(state => idx for (idx, state) in enumerate(unique_states))
    
    # Now, we create an adjacency matrix for our graph with zeros
    g = zeros(Int, length(unique_states), length(unique_states))
    edgecolor = fill(colorant"#CCCCCC", length(unique_states), length(unique_states))
    lightgreen = colormap("Greens", 100)[20]
    lightred = colormap("Reds", 100)[20]

    # We set values in the matrix to 1 for each link in the genotype
    for ((from_state, input), to_state) in geno.links
        from_idx = state_indices[from_state]
        to_idx = state_indices[to_state]
        g[from_idx, to_idx] = 1
        #if geno.links[(from_state, true)] == geno.links[(from_state, false)]
        #    edgecolor[from_idx, to_idx] = colorant"purple"
        #else
            if (from_state, to_state) ∈ edges_seen 
                edgecolor[from_idx, to_idx] = input ? colorant"green" : colorant"red"
            else
                edgecolor[from_idx, to_idx] = input ? lightgreen : lightred
            end
        #end
    end

    # Now, we create a color map for the nodes in the graph
    nodecolor = fill(colorant"#CCCCCC", length(unique_states))  # Default gray color
    nodeshape = fill(:circle, length(unique_states))  # Default gray color
    nodeshape[state_indices[geno.start]] = :rect

    # We color the ones-states in red
    for one_state in geno.ones
        nodecolor[state_indices[one_state]] = one_state ∈ seen ? colorant"green" : lightgreen
    end

    # We color the zero-states in purple (or any other desired color)
    for zero_state in geno.zeros
        nodecolor[state_indices[zero_state]] = zero_state ∈ seen ? colorant"red" : lightred
    end
    if currstate != 0
        nodecolor[state_indices[currstate]] = colorant"orange"
    end
    # Finally, we plot the graph using GraphRecipes
    graphplot(
        g,
        names = do_labels ? collect(1:length(unique_states)) : [" " for _ in 1:length(unique_states)],
        curves=true,
        color=:black,
        nodecolor=nodecolor,
        edgecolor=edgecolor,
        method=:shell,
        nodeshape=nodeshape,
        self_edge_size=self_edge_size,
        fontsize=fontsize,
        title=title,
    )
end


function dummy_small1()
    start = 1
    ones = Set([2])
    zeros = Set([1])
    links = Dict{Tuple{Int, Bool}, Int}(
    (1, 0) => 1,
    (1, 1)  => 2,
    (2, 1) => 2,
    (2, 0) => 1,)
    FSMIndiv(:dummy, UInt32(1), FSMGeno(start, ones, zeros, links))
end
function dummy_small2()
    start = 1
    ones = Set([2])
    zeros = Set([1])
    links = Dict{Tuple{Int, Bool}, Int}(
    (1, 0) => 2,
    (1, 1)  => 1,
    (2, 1) => 1,
    (2, 0) => 2,)
    FSMIndiv(:dummy, UInt32(2), FSMGeno(start, ones, zeros, links))
end
function dummy_small3()
    start = 1
    ones = Set([1])
    zeros = Set([2])
    links = Dict{Tuple{Int, Bool}, Int}(
    (1, 0) => 2,
    (1, 1)  => 1,
    (2, 1) => 1,
    (2, 0) => 2,)
    FSMIndiv(:dummy, UInt32(3), FSMGeno(start, ones, zeros, links))
end





function plot_pairs(geno1::FSMGeno, vector1::Vector{<:Pair{<:Real, Bool}}, geno2::FSMGeno, vector2::Vector{<:Pair{<:Real, Bool}}, until::Int; pair_size::Int = 15, kwargs...)
    # Initiate plot with specific settings
    plot(x=1:length(vector1), legend=false, yaxis=("", (0.5, 2.5)), yticks=(1:2, ["Right", "Left"]), xaxis=("Timestep"), xticks=(1:length(vector1), 1:length(vector1)), xlims=(0.5, length(vector1) + 0.5), markershape=:square, markersize=10)
    unique_states1 = sort(collect(union(geno1.ones, geno1.zeros)))
    state_indices1 = Dict(state => idx for (idx, state) in enumerate(unique_states1))
    unique_states2 = sort(collect(union(geno2.ones, geno2.zeros)))
    state_indices2 = Dict(state => idx for (idx, state) in enumerate(unique_states2))

    # Plottinig for vector1
    for (idx, pair) in enumerate(vector1[1:until])
        scatter!([idx], [2], markercolor = pair.second ? :green : :red, label=false, markershape=:square, markersize=pair_size)
        annotate!(idx, 2, text(state_indices1[pair.first], 12, :center, color=:black))  # annotate with the integer value
    end

    # Plotting for vector2
    for (idx, pair) in enumerate(vector2[1:until])
        scatter!([idx], [1], markercolor = pair.second ? :green : :red, label=false, markershape=:square, markersize=pair_size)
        annotate!(idx, 1, text(state_indices2[pair.first], 12, :center, color=:black))  # annotate with the integer value
    end


    # Check if the boolean results match and plot the results
    #for idx in 1:length(vector1)
    #    matches = vector1[idx].second == vector2[idx].second
    #    scatter!([idx], [0], markercolor = matches ? :green : :red, label=false)
    #    annotate!(idx, 0, text(matches ? "true" : "false", 5, :center, color=:black))  # annotate with the match result
    #end

    current()
end

# Example usage
vector1 = [1=>true, 2=>false, 3=>true, 4=>false]
vector2 = [5=>true, 6=>false, 7=>true, 8=>false]

#plot_pairs(vector1, vector2)


function anim_fsm(eco::String, trial::Int, gen::Int, role::LingPredRole,
                           leftfsm::FSMIndiv, 
                           rightfsm::FSMIndiv; fps::Float64 = 1.0, fname::String = "fsm_anim.gif", kwargs...)

    gr()
    GR.setarrowsize(0.35)
    l = @layout [a b; c{0.2h}]
    phenocfg = FSMPhenoCfg(usesets = true)
    domain = LingPredGame(role)
    outcome = stir(:visual, domain, LingPredObsConfig(), phenocfg(leftfsm), phenocfg(rightfsm))
    leftstates = outcome.obs.states[leftfsm.ikey]
    rightstates = outcome.obs.states[rightfsm.ikey]
    leftouts = outcome.obs.outs[leftfsm.ikey]
    rightouts = outcome.obs.outs[rightfsm.ikey]
    leftpairs = [state => out for (state, out) in zip(leftstates, leftouts)]
    rightpairs = [state => out for (state, out) in zip(rightstates, rightouts)]


    anim = @animate for t in 0:length(leftstates)
        print("$(t), ")
        leftseen = leftstates[1:t]
        rightseen = rightstates[1:t]
        leftcurr = t == 0 ? 0 : leftstates[t]
        rightcurr = t == 0 ? 0 : rightstates[t]
        plot1 = plot_geno(leftfsm.geno, leftcurr, leftseen; title = "$(leftfsm.ikey.spid)-$(leftfsm.ikey.iid)", kwargs...)
        plot2 = plot_geno(rightfsm.geno, rightcurr, rightseen; title = "$(rightfsm.ikey.spid)-$(rightfsm.ikey.iid)", kwargs...)
        plot3 = plot_pairs(leftfsm.geno, leftpairs, rightfsm.geno, rightpairs, t; kwargs...)
        line1 = "Ecosystem: $(eco)"
        line2 = "Trial: $(trial), Generation: $gen"
        #line3 = "$(leftfsm.ikey.spid)-$(leftfsm.ikey.iid) / $(rightfsm.ikey.spid)-$(rightfsm.ikey.iid)"
        line3 ="time: $(t)" 
        title = "$line1\n$line2\n$line3"
        plot(plot1, plot2, plot3, layout = l, size=(1200, 900), plot_title=title)
    end
    gif(anim, fname, fps = fps)
end

function anim_fsm(eco::String, trial::Int, gen::Int, role::LingPredRole,
                           leftspecies::String, leftnum::Int,
                           rightspecies::String, rightnum::Int; kwargs...)
    a = FSMIndivArchiver()
    jld = jldopen("archives/$eco/$trial.jld2")
    gengroup = jld["arxiv/$gen/species"]
    leftfsm = a(leftspecies, string(leftnum), gengroup["$leftspecies/children/$leftnum"])
    rightfsm = a(rightspecies, string(rightnum), gengroup["$rightspecies/children/$rightnum"])
    anim_fsm(eco, trial, gen, role, leftfsm, rightfsm; kwargs...)
end


