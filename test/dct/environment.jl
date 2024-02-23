using CoEvo.Concrete.Environments.ElementaryCellularAutomata
using CoEvo.Concrete.Domains.DensityClassification
using CoEvo.Interfaces
using Plots
using Test

c1 = "00000000010111110000000001011111"
c2 = "00000000010111111111111101011111"
c1 = [parse(Int, c) for c in c1]
c2 = [parse(Int, c) for c in c2]
GKL = collect(reverse([c1 ; c1 ; c2 ; c2]))

function plot_eca(states::Matrix{Int})
    # Reverse the states matrix to have the initial state at the top
    states_reversed = reverse(states, dims=1)
    
    # Define a custom color gradient: 0 -> white, 1 -> black
    cmap = cgrad([:white, :black])
    
    # Plot using a direct image representation with the custom color gradient
    heatmap(
        states_reversed, aspect_ratio=1, colorbar=false, legend=false, ticks=nothing, 
        border=:none, cmap=cmap
    )
end

function generate_IC(n::Int, rho::Int)
    v = Int[zeros(rho) ; ones(n - rho)]
    IC = shuffle(v)
    return IC
end

#IC = generate_IC(149, 50)
rule_30 = [0, 0, 0, 1, 1, 1, 1, 0]
IC = Int[zeros(21) ; 1 ; zeros(21)]

environment_creator = ElementaryCellularAutomataEnvironmentCreator(n_timesteps=16)
environment = create_environment(environment_creator, rule_30, IC)
while is_active(environment)
    step!(environment)
end

test_matrix = Int[0 0 0 1 0 ; 0 0 0 0 0]
@test measure(environment.domain, test_matrix) == [1.0, 0.0]

test_matrix = Int[0 0 0 1 0 ; 0 0 0 1 0]
@test measure(environment.domain, test_matrix) == [0.0, 1.0]

test_matrix = Int[0 1 1 1 0 ; 1 1 1 1 1]
@test measure(environment.domain, test_matrix) == [1.0, 0.0]
#plot_eca(environment.states)
test_matrix = Int[0 1 1 1 0 ; 1 1 1 1 0]
@test measure(environment.domain, test_matrix) == [0.0, 1.0]

test_matrix = Int[0 1 1 1 0 ; 0 0 0 0 0]
@test measure(environment.domain, test_matrix) == [0.0, 1.0]