using GraphNeuralNetworks
using CairoMakie
using GraphMakie
using Graphs

g = wheel_graph(10)
f, ax, p = graphplot(g)
hidedecorations!(ax); hidespines!(ax)
ax.aspect = DataAspect()
save("test.png", f)