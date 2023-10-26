using Test
#include("../../src/CoEvo.jl")
using CoEvo
using CoEvo.TapeMethods.ContinuousPredictionGame: scaled_arctangent, apply_movement, get_action!
using CoEvo.TapeMethods.ContinuousPredictionGame: get_outcome_set, get_clockwise_distance, get_counterclockwise_distance
import CoEvo.Phenotypes.Interfaces: act!, reset!

function pretty_print(env::ContinuousPredictionGameEnvironment)
    #println("ContinuousPredictionGameEnvironment:")
    #println("  Domain: ", env.domain)
    #println("  Entity 1: ", env.entity_1)
    #println("  Entity 2: ", env.entity_2)
    #println("  Episode Length: ", env.episode_length)
    println("----------------------------------")
    println("  Position 1: ", env.position_1)
    println("  Position 2: ", env.position_2)
    println("  Movement Scale: ", env.movement_scale)
    println("  Distances: ", join(env.distances, ", "))
    println("  Communication 1: ", join(env.communication_1, ", "))
    println("  Communication 2: ", join(env.communication_2, ", "))
    println("  Input Vector: ", join(env.input_vector, ", "))
end


genotype_1 = FunctionGraphGenotype(
    [649, 650, 651, 652], 
    [653], 
    [4835], 
    [654, 655, 656], 
    Dict{Int64, FunctionGraphNode}(
        650 => FunctionGraphNode(650, :INPUT, FunctionGraphConnection[]), 
        654 => FunctionGraphNode(654, :OUTPUT, FunctionGraphConnection[
            FunctionGraphConnection(650, -0.4561883229762316, false)
        ]), 
        656 => FunctionGraphNode(656, :OUTPUT, FunctionGraphConnection[
            FunctionGraphConnection(650, 0.06509867310523987, false)
        ]), 
        652 => FunctionGraphNode(652, :INPUT, FunctionGraphConnection[]), 
        4835 => FunctionGraphNode(4835, :RELU, FunctionGraphConnection[
            FunctionGraphConnection(649, -0.19246595725417137, true)
        ]), 
        653 => FunctionGraphNode(653, :BIAS, FunctionGraphConnection[]), 
        651 => FunctionGraphNode(651, :INPUT, FunctionGraphConnection[]), 
        649 => FunctionGraphNode(649, :INPUT, FunctionGraphConnection[]), 
        655 => FunctionGraphNode(655, :OUTPUT, FunctionGraphConnection[
            FunctionGraphConnection(652, 0.1383829526603222, false)
        ])
    )
)

genotype_2 = FunctionGraphGenotype(
    [3097, 3098, 3099, 3100], 
    [3101], 
    Int64[], 
    [3102, 3103, 3104], 
    Dict{Int64, FunctionGraphNode}(
        3102 => FunctionGraphNode(3102, :OUTPUT, [
            FunctionGraphConnection(3101, -0.24677674379199743, false)
        ]), 
        3100 => FunctionGraphNode(3100, :INPUT, FunctionGraphConnection[]), 
        3103 => FunctionGraphNode(3103, :OUTPUT, [
            FunctionGraphConnection(3099, 0.15320174527005292, false)
        ]), 
        3098 => FunctionGraphNode(3098, :INPUT, FunctionGraphConnection[]), 
        3097 => FunctionGraphNode(3097, :INPUT, FunctionGraphConnection[]), 
        3101 => FunctionGraphNode(3101, :BIAS, FunctionGraphConnection[]), 
        3099 => FunctionGraphNode(3099, :INPUT, FunctionGraphConnection[]), 
        3104 => FunctionGraphNode(3104, :OUTPUT, [
            FunctionGraphConnection(3100, 0.15407671313732862, false)
        ])
    )
)

using Serialization

#genotype_1 = deserialize("mutualist_1.jls")
#genotype_2 = deserialize("parasite_1.jls")
#genotype_1 = deserialize("host_1.jls")
#genotype_2 = deserialize("parasite_1.jls")
#genotype_2 = deserialize("mutualist_1.jls")

using .Genotypes.Interfaces: minimize, get_size
println("----------------------")
println("MIN_SIZE")

println(get_size(minimize(genotype_1)))
println(get_size(minimize(genotype_2)))

phenotype_1 = create_phenotype(LinearizedFunctionGraphPhenotypeCreator(), genotype_1)
phenotype_2 = create_phenotype(LinearizedFunctionGraphPhenotypeCreator(), genotype_2)

domain_mock = ContinuousPredictionGameDomain(:CooperativeMatching)

environment = create_environment(ContinuousPredictionGameEnvironmentCreator(
    domain=domain_mock, episode_length=32), 
    Phenotype[phenotype_1, phenotype_2]
)

positions_1 = Float32[]
positions_2 = Float32[]
communications_1 = Vector{Float32}[]
communications_2 = Vector{Float32}[]

push!(positions_1, environment.position_1)
push!(positions_2, environment.position_2)
push!(communications_1, [0.0f0, 0.0f0])
push!(communications_2, [0.0f0, 0.0f0])
push!(positions_1, environment.position_1)
push!(positions_2, environment.position_2)
push!(communications_1, [0.0f0, 0.0f0])
push!(communications_2, [0.0f0, 0.0f0])
pretty_print(environment)
for _ in 1:31
    next!(environment)
    pretty_print(environment)
    push!(positions_1, environment.position_1)
    push!(positions_2, environment.position_2)
    push!(communications_1, environment.communication_1)
    push!(communications_2, environment.communication_2)
end
println(length(positions_1))



using Plots
using Colors

function color_from_communication(value::Real)
    # Convert the value range from [-π/2, π/2] to [0, 1]
    normalized = (value + π/2) / π
    colors = colormap("RdBu", 100)  # Retrieve the RdBu colormap with 100 colors
    idx = min(ceil(Int, normalized * 99) + 1, length(colors))
    return colors[idx]
end

# Linear interpolation for angles
function lerp_angle(a, b, t)
    diff = b - a
    if diff > π
        b -= 2π
    elseif diff < -π
        b += 2π
    end
    return a + (b - a) * t
end

function lerp(a, b, t)
    return a + (b - a) * t
end

function plot_arc_interpolated(p, x, y, circle_radius, border_color, left_color, right_color)
    # Left half
    plot!(
        p, 
        [x; x .+ circle_radius*cos.(π:0.01:2π)], [y; y .+ circle_radius*sin.(π:0.01:2π)], seriestype=:shape, linecolor=border_color, fillcolor=left_color, label="", linewidth=3.0)
    
    # Right half
    plot!(p, [x; x .+ circle_radius*cos.(0:0.01:π)], [y; y .+ circle_radius*sin.(0:0.01:π)], seriestype=:shape, linecolor=border_color, fillcolor=right_color, label="", linewidth=3.0)
end

function plot_shortest_arc(p, pos1, pos2; color=:orange, linewidth=2.0)
    if abs(pos2 - pos1) <= π
        start_angle = min(pos1, pos2)
        end_angle = max(pos1, pos2)
    else
        # If the direct arc is greater than π, we go the other way around
        start_angle = max(pos1, pos2)
        end_angle = min(pos1, pos2) + 2π
    end
    plot!(p, cos.(start_angle:0.01:end_angle), sin.(start_angle:0.01:end_angle), seriestype=:path, linecolor=color, label="", linewidth=linewidth)
end

using LinearAlgebra  # For norm()

function plot_interaction(
    positions1::Vector{Float32}, 
    positions2::Vector{Float32}, 
    comm1::Vector{Vector{Float32}}, 
    comm2::Vector{Vector{Float32}};
    interpolation_steps=5,
    name1="Agent 1",
    name2="Agent 2",
    border_color1=:red,
    border_color2=:green,
    distance_line_thickness=2.0,
    filename="interaction.gif"
)
    function distance_on_circle(pos1, pos2)
        d = abs(pos2 - pos1)
        return min(d, 2π - d)
    end

    gr()
    anim = Animation()
    cumulative_distance = 0.0
    for t in 1:length(positions1)-1
        cumulative_distance += distance_on_circle(positions1[t], positions2[t])#) / interpolation_steps
        for _ in 1:Int(0.5 * interpolation_steps)
            p = plot(; xlims=(-1.2, 1.2), ylims=(-1.2, 1.2), aspect_ratio=:equal, legend=false, grid=false, xticks=false, yticks=false, framestyle=:none, title="Timestep: $(t) \n $name1 and $name2 \n Cumulative Distance: $(round(cumulative_distance, digits=2))")
            
            plot!(cos.(0:0.01:2π), sin.(0:0.01:2π), linewidth=2.0, linecolor=:black, label="", fillalpha=0)
            plot_shortest_arc(p, positions1[t], positions2[t], color=:orange, linewidth=distance_line_thickness)
            
            x1, y1 = cos(positions1[t]), sin(positions1[t])
            plot_arc_interpolated(p, x1, y1, 0.1, border_color1, color_from_communication(comm1[t][1]), color_from_communication(comm1[t][2]))
            
            x2, y2 = cos(positions2[t]), sin(positions2[t])
            plot_arc_interpolated(p, x2, y2, 0.1, border_color2, color_from_communication(comm2[t][1]), color_from_communication(comm2[t][2]))
            
            frame(anim)
        end
        for step in 1:interpolation_steps
            ratio = step / interpolation_steps
            #cumulative_distance += distance_on_circle(positions1[t], positions2[t]) / interpolation_steps
            p = plot(; xlims=(-1.2, 1.2), ylims=(-1.2, 1.2), aspect_ratio=:equal, legend=false, grid=false, xticks=false, yticks=false, framestyle=:none, title="Timestep: $(t) \n $name1 and $name2 \n Cumulative Distance: $(round(cumulative_distance, digits=2))")
            
            plot!(cos.(0:0.01:2π), sin.(0:0.01:2π), linewidth=2.0, linecolor=:black, label="", fillalpha=0)
            plot_shortest_arc(p, positions1[t], positions2[t], color=:orange, linewidth=distance_line_thickness)
            
            # Interpolated positions
            interp_pos1 = lerp_angle(positions1[t], positions1[t+1], ratio)
            interp_pos2 = lerp_angle(positions2[t], positions2[t+1], ratio)
            
            # Interpolated communications
            interp_comm1_1 = lerp(comm1[t][1], comm1[t+1][1], ratio)
            interp_comm1_2 = lerp(comm1[t][2], comm1[t+1][2], ratio)
            interp_comm2_1 = lerp(comm2[t][1], comm2[t+1][1], ratio)
            interp_comm2_2 = lerp(comm2[t][2], comm2[t+1][2], ratio)

            circle_radius = 0.1  # Adjust this value for a larger or smaller circle
            
            # Agent 1
            x1, y1 = cos(interp_pos1), sin(interp_pos1)
            plot_arc_interpolated(p, x1, y1, circle_radius, border_color1, color_from_communication(interp_comm1_1), color_from_communication(interp_comm1_2))
            
            # Agent 2
            x2, y2 = cos(interp_pos2), sin(interp_pos2)
            plot_arc_interpolated(p, x2, y2, circle_radius, border_color2, color_from_communication(interp_comm2_1), color_from_communication(interp_comm2_2))
            
            frame(anim)
        end
    end
    
    gif(anim, filename, fps=interpolation_steps)
end
plot_interaction(
    positions_1, positions_2, communications_1, communications_2, 
    interpolation_steps = 20, 
    name1="Host_1", 
    name2="Mutualist_1", 
    border_color1=:blue, 
    border_color2=:green, 
    distance_line_thickness=3.0,
    filename = "interaction_degenerate.gif"
)


