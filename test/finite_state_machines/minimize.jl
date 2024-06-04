using Test

@testset "Minimize" begin

using Random
using StableRNGs
using CoEvo
#using .Genotypes: minimize 
using .CoEvo.Interfaces
#using .Genotypes.FiniteStateMachines: FiniteStateMachineGenotype, minimize_verbose

@testset "cornell1" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.1"
    start = "0"
    a = false 
    b = true
    ones  = Set(["0", "3"])
    zeros = Set(["1", "2"])
    links = Dict(
        ("0", a) => "1",
        ("0", b) => "2",
        ("1", a) => "3",
        ("1", b) => "3",
        ("2", a) => "3",
        ("2", b) => "3",
        ("3", a) => "3",
        ("3", b) => "3",
    )

    max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
    minimized_genotype, _ = minimize_verbose(max1)

    @test minimized_genotype.start == "0/"
    @test length(minimized_genotype.links) == 6
    @test minimized_genotype.ones == Set(["0/", "3/"])
    @test minimized_genotype.zeros == Set(["1/2"])
    @test minimized_genotype.links[("0/",  a)] == "1/2"
    @test minimized_genotype.links[("0/",  b)] == "1/2"
    @test minimized_genotype.links[("1/2", a)] == "3/"
    @test minimized_genotype.links[("1/2", b)] == "3/"
    @test minimized_genotype.links[("3/",  a)] == "3/"
    @test minimized_genotype.links[("3/",  b)] == "3/"
end

@testset "cornell1int" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.1"
    start = 0
    a = false
    b = true
    ones  = Set([0, 3])
    zeros = Set([1, 2])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, a) => 1,
        (0, b) => 2,
        (1, a) => 3,
        (1, b) => 3,
        (2, a) => 3,
        (2, b) => 3,
        (3, a) => 3,
        (3, b) => 3,
    )

    max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
    minimized_genotype, merged_state_map = minimize_verbose(max1)

    @test minimized_genotype.start == merged_state_map[0]
    @test length(minimized_genotype.links) == 6
    @test minimized_genotype.ones == Set([merged_state_map[0], merged_state_map[3]])
    @test minimized_genotype.zeros == Set([merged_state_map[1]])
    links = Dict{Tuple{Int, Bool}, Int}(
        (merged_state_map[0], a) => merged_state_map[1],
        (merged_state_map[0], b) => merged_state_map[1],
        (merged_state_map[1], a) => merged_state_map[3],
        (merged_state_map[1], b) => merged_state_map[3],
        (merged_state_map[3], a) => merged_state_map[3],
        (merged_state_map[3], b) => merged_state_map[3],
    )
    @test minimized_genotype.links == links
end
# # 
@testset "cornell2" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.2"
    start = "0"
    a = false
    b = true
    ones  = Set(["0", "3", "4"])
    zeros = Set(["1", "2", "5"])
    links = Dict(
                ("0", a) => "1",
                ("0", b) => "2",
                ("1", a) => "3",
                ("1", b) => "4",
                ("2", a) => "4",
                ("2", b) => "3",
                ("3", a) => "5",
                ("3", b) => "5",
                ("4", a) => "5",
                ("4", b) => "5",
                ("5", a) => "5",
                ("5", b) => "5",
                )

    max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
    minimized_genotype, _ = minimize_verbose(max1)

    six = "0/"
    seven = "1/2"
    eight = "3/4"
    nine = "5/"

    @test minimized_genotype.start == six
    @test length(minimized_genotype.links) == 8
    @test minimized_genotype.ones == Set([six, eight])
    @test minimized_genotype.zeros == Set([seven, nine])
    @test minimized_genotype.links[(six,   a)] == seven
    @test minimized_genotype.links[(six,   b)] == seven
    @test minimized_genotype.links[(seven, a)] == eight
    @test minimized_genotype.links[(seven, b)] == eight
    @test minimized_genotype.links[(eight, a)] == nine
    @test minimized_genotype.links[(eight, b)] == nine
    @test minimized_genotype.links[(nine,  a)] == nine
    @test minimized_genotype.links[(nine,  b)] == nine
end
# 
@testset "cornell2int" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.2"
    start = 0
    a = false
    b = true
    ones  = Set([0, 3, 4])
    zeros = Set([1, 2, 5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, a) => 1,
        (0, b) => 2,
        (1, a) => 3,
        (1, b) => 4,
        (2, a) => 4,
        (2, b) => 3,
        (3, a) => 5,
        (3, b) => 5,
        (4, a) => 5,
        (4, b) => 5,
        (5, a) => 5,
        (5, b) => 5,
    )

    max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
    minimized_genotype, merged_state_map = minimize_verbose(max1)

    six = merged_state_map[0]
    seven = merged_state_map[1]
    eight = merged_state_map[3]
    nine = merged_state_map[5]

    @test minimized_genotype.start == six
    @test length(minimized_genotype.links) == 8
    @test minimized_genotype.ones == Set([six, eight])
    @test minimized_genotype.zeros == Set([seven, nine])
    links = Dict{Tuple{Int, Bool}, Int}(
        (six,   a) => seven,
        (six,   b) => seven,
        (seven, a) => eight,
        (seven, b) => eight,
        (eight, a) => nine,
        (eight, b) => nine,
        (nine,  a) => nine,
        (nine,  b) => nine,
    )
    @test minimized_genotype.links == links
end
# 
# 
# 
@testset "cornell3" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.3"
    start = "0"
    a = false
    b = true
    ones  = Set(["0", "1", "2"])
    zeros = Set(["3", "4", "5"])
    links = Dict(
                ("0", a) => "1",
                ("0", b) => "2",
                ("1", a) => "3",
                ("1", b) => "4",
                ("2", a) => "4",
                ("2", b) => "3",
                ("3", a) => "5",
                ("3", b) => "5",
                ("4", a) => "5",
                ("4", b) => "5",
                ("5", a) => "5",
                ("5", b) => "5",
                )

    max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
    minimized_genotype, _ = minimize_verbose(max1)

    six = "0/"
    seven = "1/2"
    eight = "3/4/5"

    @test minimized_genotype.start == six
    @test length(minimized_genotype.links) == 6
    @test minimized_genotype.ones == Set([six, seven])
    @test minimized_genotype.zeros == Set([eight])
    @test minimized_genotype.links[(six,   a)] == seven
    @test minimized_genotype.links[(six,   b)] == seven
    @test minimized_genotype.links[(seven, a)] == eight
    @test minimized_genotype.links[(seven, b)] == eight
    @test minimized_genotype.links[(eight, a)] == eight
    @test minimized_genotype.links[(eight, b)] == eight
end
# 
@testset "cornell3int" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.3"
    start = 0
    a = false
    b = true
    ones  = Set([0, 1, 2])
    zeros = Set([3, 4, 5])
    links = Dict{Tuple{Int, Bool}, Int}(
        (0, a) => 1,
        (0, b) => 2,
        (1, a) => 3,
        (1, b) => 4,
        (2, a) => 4,
        (2, b) => 3,
        (3, a) => 5,
        (3, b) => 5,
        (4, a) => 5,
        (4, b) => 5,
        (5, a) => 5,
        (5, b) => 5,
    )

    max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
    minimized_genotype, merged_state_map = minimize_verbose(max1)

    six = merged_state_map[0]
    seven = merged_state_map[1]
    eight = merged_state_map[3]

    @test minimized_genotype.start == six
    @test length(minimized_genotype.links) == 6
    @test minimized_genotype.ones == Set([six, seven])
    @test minimized_genotype.zeros == Set([eight])
    links = Dict{Tuple{Int, Bool}, Int}(
        (six,   a) => seven,
        (six,   b) => seven,
        (seven, a) => eight,
        (seven, b) => eight,
        (eight, a) => eight,
        (eight, b) => eight,
    )
    @test minimized_genotype.links == links
end
# 
# @testset "cornell4" begin
#     source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
#     example = "13.4"
#     start = "1"
#     a = false
#     b = true
#     ones = Set(["1", "3", "4", "6", "7"])
#     zeros = Set(["2", "5"])
#     links = Dict(
#                 ("1", a) => "7",
#                 ("1", b) => "2",
#                 ("2", a) => "7",
#                 ("2", b) => "3",
#                 ("3", a) => "7",
#                 ("3", b) => "4",
#                 ("4", a) => "7",
#                 ("4", b) => "5",
#                 ("5", a) => "7",
#                 ("5", b) => "6",
#                 ("6", a) => "7",
#                 ("6", b) => "1",
#                 ("7", a) => "7",
#                 ("7", b) => "7",
#                 )
# 
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype = minimize(max1)
# 
#     @test minimized_genotype.start == "1/4"
#     @test length(minimized_genotype.links) == 8
#     @test minimized_genotype.ones == Set(["1/4", "3/6", "7/"])
#     @test minimized_genotype.zeros == Set(["2/5"])
#     @test minimized_genotype.links[("1/4", a)] == "7/"
#     @test minimized_genotype.links[("1/4", b)] == "2/5"
#     @test minimized_genotype.links[("2/5", a)] == "7/"
#     @test minimized_genotype.links[("2/5", b)] == "3/6"
#     @test minimized_genotype.links[("3/6", a)] == "7/"
#     @test minimized_genotype.links[("3/6", b)] == "1/4"
#     @test minimized_genotype.links[("7/", a)] == "7/"
#     @test minimized_genotype.links[("7/", b)] == "7/"
# 
#     # printtest(source, example, max1, minimized_genotype)
# end
# 
# @testset "cornell4int" begin
#     source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
#     example = "13.4"
#     start = 1
#     a = false
#     b = true
#     ones = Set([1, 3, 4, 6, 7])
#     zeros = Set([2, 5])
# 
#     links = Dict{Tuple{Int, Bool}, Int}(
#         (1, a) => 7,
#         (1, b) => 2,
#         (2, a) => 7,
#         (2, b) => 3,
#         (3, a) => 7,
#         (3, b) => 4,
#         (4, a) => 7,
#         (4, b) => 5,
#         (5, a) => 7,
#         (5, b) => 6,
#         (6, a) => 7,
#         (6, b) => 1,
#         (7, a) => 7,
#         (7, b) => 7,
#     )
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype, merged_state_map = minimize_verbose(max1)
#     @test minimized_genotype.start == merged_state_map[1]
#     @test length(minimized_genotype.links) == 8
#     @test minimized_genotype.ones == Set([merged_state_map[1], merged_state_map[3], merged_state_map[7]])
#     @test minimized_genotype.zeros == Set([merged_state_map[2]])
#     newlinks = Dict{Tuple{Int, Bool}, Int}(
#         (merged_state_map[1], a) => merged_state_map[7],
#         (merged_state_map[1], b) => merged_state_map[2],
#         (merged_state_map[2], a) => merged_state_map[7],
#         (merged_state_map[2], b) => merged_state_map[3],
#         (merged_state_map[3], a) => merged_state_map[7],
#         (merged_state_map[3], b) => merged_state_map[1],
#         (merged_state_map[7], a) => merged_state_map[7],
#         (merged_state_map[7], b) => merged_state_map[7],
#     )
# 
#     @test minimized_genotype.links == newlinks
# end
# 
# # 
# @testset "neso1" begin
#     source = "https://www.youtube.com/watch?v=0XaGAkY09Wc"
#     example = "1"
#     start = "A"
#     ones = Set(["A", "B", "C", "D"])
#     zeros = Set(["E"])
#     links = Dict(
#                 ("A", 0) => "B",
#                 ("A", 1) => "C",
#                 ("B", 0) => "B",
#                 ("B", 1) => "D",
#                 ("C", 0) => "B",
#                 ("C", 1) => "C",
#                 ("D", 0) => "B",
#                 ("D", 1) => "E",
#                 ("E", 0) => "B",
#                 ("E", 1) => "C",
#                 )
# 
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype = minimize(max1)
# 
#     @test minimized_genotype.start == "A/C"
#     @test length(minimized_genotype.links) == 8
#     @test minimized_genotype.ones == Set(["A/C", "B/", "D/"])
#     @test minimized_genotype.zeros == Set(["E/"])
#     @test minimized_genotype.links[("A/C", 0)] == "B/"
#     @test minimized_genotype.links[("A/C", 1)] == "A/C"
#     @test minimized_genotype.links[("B/",  0)] == "B/"
#     @test minimized_genotype.links[("B/",  1)] == "D/"
#     @test minimized_genotype.links[("D/",  0)] == "B/"
#     @test minimized_genotype.links[("D/",  1)] == "E/"
#     @test minimized_genotype.links[("E/",  0)] == "B/"
#     @test minimized_genotype.links[("E/",  1)] == "A/C"
# 
#     # printtest(source, example, max1, minimized_genotype)
# end
# 
# @testset "neso2" begin
#     source = "https://www.youtube.com/watch?v=ex9sPLq5CRg"
#     example = "2"
#     start = "q0"
#     ones = Set(["q0", "q1", "q3", "q4", "q5", "q6", "q7"])
#     zeros = Set(["q2"])
#     links = Dict(
#                 ("q0", 0) => "q1",
#                 ("q0", 1) => "q5",
#                 ("q1", 0) => "q6",
#                 ("q1", 1) => "q2",
#                 ("q2", 0) => "q0",
#                 ("q2", 1) => "q2",
#                 ("q3", 0) => "q2",
#                 ("q3", 1) => "q6",
#                 ("q4", 0) => "q7",
#                 ("q4", 1) => "q5",
#                 ("q5", 0) => "q2",
#                 ("q5", 1) => "q6",
#                 ("q6", 0) => "q6",
#                 ("q6", 1) => "q4",
#                 ("q7", 0) => "q6",
#                 ("q7", 1) => "q2",
#                 )
# 
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype = minimize(max1)
# 
#     @test minimized_genotype.start == "q0/q4"
#     @test length(minimized_genotype.links) == 10
#     @test minimized_genotype.ones == Set(["q0/q4", "q6/", "q1/q7", "q5/"])
#     @test minimized_genotype.zeros == Set(["q2/"])
#     @test minimized_genotype.links[("q0/q4", 0)] == "q1/q7"
#     @test minimized_genotype.links[("q0/q4", 1)] == "q5/"
#     @test minimized_genotype.links[("q6/",   0)] == "q6/"
#     @test minimized_genotype.links[("q6/",   1)] == "q0/q4"
#     @test minimized_genotype.links[("q1/q7", 0)] == "q6/"
#     @test minimized_genotype.links[("q1/q7", 1)] == "q2/"
#     @test minimized_genotype.links[("q5/",   0)] == "q2/"
#     @test minimized_genotype.links[("q5/",   1)] == "q6/"
#     @test minimized_genotype.links[("q2/",   0)] == "q0/q4"
#     @test minimized_genotype.links[("q2/",   1)] == "q2/"
# end
# 
# @testset "neso3" begin
#     source = "https://www.youtube.com/watch?v=DV8cZp-2VmM"
#     example = "3"
#     start = "A"
#     ones = Set(["A", "B", "F"])
#     zeros = Set(["C", "D", "E"])
#     links = Dict(
#                 ("A", 0) => "B",
#                 ("A", 1) => "C",
#                 ("B", 0) => "A",
#                 ("B", 1) => "D",
#                 ("C", 0) => "E",
#                 ("C", 1) => "F",
#                 ("D", 0) => "E",
#                 ("D", 1) => "F",
#                 ("E", 0) => "E",
#                 ("E", 1) => "F",
#                 ("F", 0) => "F",
#                 ("F", 1) => "F",
#                 )
# 
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype = minimize(max1)
# 
#     @test minimized_genotype.start == "A/B"
#     @test length(minimized_genotype.links) == 6
#     @test minimized_genotype.ones == Set(["A/B", "F/"])
#     @test minimized_genotype.zeros == Set(["C/D/E"])
#     @test minimized_genotype.links[("A/B",   0)] == "A/B"
#     @test minimized_genotype.links[("A/B",   1)] == "C/D/E"
#     @test minimized_genotype.links[("F/",    0)] == "F/"
#     @test minimized_genotype.links[("F/",    1)] == "F/"
#     @test minimized_genotype.links[("C/D/E", 0)] == "C/D/E"
#     @test minimized_genotype.links[("C/D/E", 1)] == "F/"
# end
# 
# @testset "neso4" begin
#     source = "https://www.youtube.com/watch?v=kYMqDgB2GbU"
#     example = "4"
#     start = "A"
#     ones = Set(["A", "D", "E", "F"])
#     zeros = Set(["B", "C", "G"])
#     links = Dict(
#                 ("A", 0) => "B",
#                 ("A", 1) => "C",
#                 ("B", 0) => "D",
#                 ("B", 1) => "E",
#                 ("C", 0) => "E",
#                 ("C", 1) => "D",
#                 ("D", 0) => "G",
#                 ("D", 1) => "G",
#                 ("E", 0) => "G",
#                 ("E", 1) => "G",
#                 ("F", 0) => "D",
#                 ("F", 1) => "E",
#                 ("G", 0) => "G",
#                 ("G", 1) => "G",
#                 )
# 
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype = minimize(max1)
# 
#     @test minimized_genotype.start == "A/"
#     @test length(minimized_genotype.links) == 8
#     @test minimized_genotype.ones == Set(["A/", "D/E"])
#     @test minimized_genotype.zeros == Set(["B/C", "G/"])
#     @test minimized_genotype.links[("A/",  0)] == "B/C"
#     @test minimized_genotype.links[("A/",  1)] == "B/C"
#     @test minimized_genotype.links[("D/E", 0)] == "G/"
#     @test minimized_genotype.links[("D/E", 1)] == "G/"
#     @test minimized_genotype.links[("B/C", 0)] == "D/E"
#     @test minimized_genotype.links[("B/C", 1)] == "D/E"
#     @test minimized_genotype.links[("G/",  0)] == "G/"
#     @test minimized_genotype.links[("G/",  1)] == "G/"
# end
# 
# @testset "westchester1" begin
#     source = "https://www.cs.wcupa.edu/rkline/fcs/dfa-min.html"
#     example = "2-20"
#     start = "q1"
#     ones = Set(["q2", "q4", "q5", "q6"])
#     zeros = Set(["q1", "q3"])
#     links = Dict(
#                 ("q1", 0) => "q2",
#                 ("q1", 1) => "q4",
#                 ("q2", 0) => "q5",
#                 ("q2", 1) => "q3",
#                 ("q3", 0) => "q2",
#                 ("q3", 1) => "q6",
#                 ("q4", 0) => "q1",
#                 ("q4", 1) => "q5",
#                 ("q5", 0) => "q5",
#                 ("q5", 1) => "q5",
#                 ("q6", 0) => "q3",
#                 ("q6", 1) => "q5",
#                 )
# 
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype = minimize(max1)
# 
#     @test minimized_genotype.start == "q1/q3"
#     @test length(minimized_genotype.links) == 8
#     @test minimized_genotype.ones == Set(["q2/", "q4/q6", "q5/"])
#     @test minimized_genotype.zeros == Set(["q1/q3"])
#     @test minimized_genotype.links[("q1/q3", 0)] == "q2/"
#     @test minimized_genotype.links[("q1/q3", 1)] == "q4/q6"
#     @test minimized_genotype.links[("q2/",   0)] == "q5/"
#     @test minimized_genotype.links[("q2/",   1)] == "q1/q3"
#     @test minimized_genotype.links[("q4/q6", 0)] == "q1/q3"
#     @test minimized_genotype.links[("q4/q6", 1)] == "q5/"
#     @test minimized_genotype.links[("q5/",   0)] == "q5/"
#     @test minimized_genotype.links[("q5/",   1)] == "q5/"
# end
# 
# @testset "odu1" begin
#     source = "https://www.cs.odu.edu/~toida/nerzic/390teched/regular/fa/min-fa.html"
#     example = "1"
#     start = "1"
#     ones = Set(["2", "3", "4"])
#     zeros = Set(["1", "5"])
#     links = Dict(
#                 ("1", 0) => "3",
#                 ("1", 1) => "2",
#                 ("2", 0) => "4",
#                 ("2", 1) => "1",
#                 ("3", 0) => "5",
#                 ("3", 1) => "4",
#                 ("4", 0) => "4",
#                 ("4", 1) => "4",
#                 ("5", 0) => "3",
#                 ("5", 1) => "2",
#                 )
# 
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype = minimize(max1)
# 
#     @test minimized_genotype.start == "1/5"
#     @test length(minimized_genotype.links) == 8
#     @test minimized_genotype.ones == Set(["2/", "3/", "4/"])
#     @test minimized_genotype.zeros == Set(["1/5"])
#     @test minimized_genotype.links[("1/5", 0)] == "3/"
#     @test minimized_genotype.links[("1/5", 1)] == "2/"
#     @test minimized_genotype.links[("2/",  0)] == "4/"
#     @test minimized_genotype.links[("2/",  1)] == "1/5"
#     @test minimized_genotype.links[("3/",  0)] == "1/5"
#     @test minimized_genotype.links[("3/",  1)] == "4/"
#     @test minimized_genotype.links[("4/",  0)] == "4/"
#     @test minimized_genotype.links[("4/",  1)] == "4/"
# end
# 
# @testset "odu2" begin
#     source = "https://www.cs.odu.edu/~toida/nerzic/390teched/regular/fa/min-fa.html"
#     example = "2"
#     start = "1"
#     ones  = Set(["3"])
#     zeros = Set(["1", "2", "4", "5", "6"])
#     links = Dict(
#                 ("1", 0) => "2",
#                 ("1", 1) => "3",
#                 ("2", 0) => "2",
#                 ("2", 1) => "4",
#                 ("3", 0) => "3",
#                 ("3", 1) => "3",
#                 ("4", 0) => "6",
#                 ("4", 1) => "3",
#                 ("5", 0) => "5",
#                 ("5", 1) => "3",
#                 ("6", 0) => "5",
#                 ("6", 1) => "4",
#                 )
# 
#     max1 = FiniteStateMachineGenotype(start, ones, zeros, links)
#     minimized_genotype = minimize(max1)
# 
#     @test minimized_genotype.start == "1/"
#     @test length(minimized_genotype.links) == 12
#     @test minimized_genotype.ones == Set(["3/"])
#     @test minimized_genotype.zeros == Set(["1/", "2/", "4/", "5/", "6/"])
#     @test minimized_genotype.links[("1/", 0)] == "2/"
#     @test minimized_genotype.links[("1/", 1)] == "3/"
#     @test minimized_genotype.links[("2/", 0)] == "2/"
#     @test minimized_genotype.links[("2/", 1)] == "4/"
#     @test minimized_genotype.links[("3/", 0)] == "3/"
#     @test minimized_genotype.links[("3/", 1)] == "3/"
#     @test minimized_genotype.links[("4/", 0)] == "6/"
#     @test minimized_genotype.links[("4/", 1)] == "3/"
#     @test minimized_genotype.links[("5/", 0)] == "5/"
#     @test minimized_genotype.links[("5/", 1)] == "3/"
#     @test minimized_genotype.links[("6/", 0)] == "5/"
#     @test minimized_genotype.links[("6/", 1)] == "4/"
# end

end
