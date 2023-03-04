# using Test
# using Random
# using StableRNGs
# include("../../src/Coevolutionary.jl")
# using .Coevolutionary

verbose = false

function printtest(source, example, maxfsm, minfsm)
    if verbose
        println("------")
        println("Source: ", source)
        println("Example: ", example)
        println()
        println("Entire machine")
        printFSM(maxfsm)
        println()
        println("Minimized machine")
        printFSM(minfsm)
    end
end

@testset "Hopcroft" begin

@testset "cornell1" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.1"
    ikey = IndivKey(:cornell1, 1)
    start = "0"
    a = 0
    b = 1
    ones  = Set(["0", "3"])
    zeros = Set(["1", "2"])
    links = LinkDict(
                ("0", a) => "1",
                ("0", b) => "2",
                ("1", a) => "3",
                ("1", b) => "3",
                ("2", a) => "3",
                ("2", b) => "3",
                ("3", a) => "3",
                ("3", b) => "3",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1).mingeno

    @test min1.start == "0/"
    @test length(min1.links) == 6
    @test min1.ones == Set(["0/", "3/"])
    @test min1.zeros == Set(["1/2"])
    @test min1.links[("0/",  a)] == "1/2"
    @test min1.links[("0/",  b)] == "1/2"
    @test min1.links[("1/2", a)] == "3/"
    @test min1.links[("1/2", b)] == "3/"
    @test min1.links[("3/",  a)] == "3/"
    @test min1.links[("3/",  b)] == "3/"

    # printtest(source, example, max1, min1)
end

@testset "cornell1int" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.1"
    start = 0
    a = 0
    b = 1
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

    max1 = FSMGeno(start, ones, zeros, links)
    min1, mm = minimize(max1; getmm = true)

    @test min1.start == mm[0]
    @test length(min1.links) == 6
    @test min1.ones == Set([mm[0], mm[3]])
    @test min1.zeros == Set([mm[1]])
    links = Dict{Tuple{Int, Bool}, Int}(
        (mm[0], a) => mm[1],
        (mm[0], b) => mm[1],
        (mm[1], a) => mm[3],
        (mm[1], b) => mm[3],
        (mm[3], a) => mm[3],
        (mm[3], b) => mm[3],
    )
    @test min1.links == links

    # printtest(source, example, max1, min1)
end

@testset "cornell2" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.2"
    ikey = IndivKey(:cornell2, 1)
    start = "0"
    a = 0
    b = 1
    ones  = Set(["0", "3", "4"])
    zeros = Set(["1", "2", "5"])
    links = LinkDict(
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

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1).mingeno

    six = "0/"
    seven = "1/2"
    eight = "3/4"
    nine = "5/"

    @test min1.start == six
    @test length(min1.links) == 8
    @test min1.ones == Set([six, eight])
    @test min1.zeros == Set([seven, nine])
    @test min1.links[(six,   a)] == seven
    @test min1.links[(six,   b)] == seven
    @test min1.links[(seven, a)] == eight
    @test min1.links[(seven, b)] == eight
    @test min1.links[(eight, a)] == nine
    @test min1.links[(eight, b)] == nine
    @test min1.links[(nine,  a)] == nine
    @test min1.links[(nine,  b)] == nine

    # printtest(source, example, max1, min1)
end

@testset "cornell2int" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.2"
    start = 0
    a = 0
    b = 1
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

    max1 = FSMGeno(start, ones, zeros, links)
    min1, mm = minimize(max1; getmm = true)

    six = mm[0]
    seven = mm[1]
    eight = mm[3]
    nine = mm[5]

    @test min1.start == six
    @test length(min1.links) == 8
    @test min1.ones == Set([six, eight])
    @test min1.zeros == Set([seven, nine])
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
    @test min1.links == links

    # printtest(source, example, max1, min1)
end



@testset "cornell3" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.3"
    ikey = IndivKey(:cornell3, 1)
    start = "0"
    a = 0
    b = 1
    ones  = Set(["0", "1", "2"])
    zeros = Set(["3", "4", "5"])
    links = LinkDict(
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

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1).mingeno

    six = "0/"
    seven = "1/2"
    eight = "3/4/5"

    @test min1.start == six
    @test length(min1.links) == 6
    @test min1.ones == Set([six, seven])
    @test min1.zeros == Set([eight])
    @test min1.links[(six,   a)] == seven
    @test min1.links[(six,   b)] == seven
    @test min1.links[(seven, a)] == eight
    @test min1.links[(seven, b)] == eight
    @test min1.links[(eight, a)] == eight
    @test min1.links[(eight, b)] == eight

    # printtest(source, example, max1, min1)
end

@testset "cornell3int" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.3"
    start = 0
    a = 0
    b = 1
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

    max1 = FSMGeno(start, ones, zeros, links)
    min1, mm = minimize(max1; getmm = true)

    six = mm[0]
    seven = mm[1]
    eight = mm[3]

    @test min1.start == six
    @test length(min1.links) == 6
    @test min1.ones == Set([six, seven])
    @test min1.zeros == Set([eight])
    links = Dict{Tuple{Int, Bool}, Int}(
        (six,   a) => seven,
        (six,   b) => seven,
        (seven, a) => eight,
        (seven, b) => eight,
        (eight, a) => eight,
        (eight, b) => eight,
    )
    @test min1.links == links

    # printtest(source, example, max1, min1)
end

@testset "cornell4" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.4"
    ikey = IndivKey(:cornell4, 1)
    start = "1"
    a = 0
    b = 1
    ones = Set(["1", "3", "4", "6", "7"])
    zeros = Set(["2", "5"])
    links = LinkDict(
                ("1", a) => "7",
                ("1", b) => "2",
                ("2", a) => "7",
                ("2", b) => "3",
                ("3", a) => "7",
                ("3", b) => "4",
                ("4", a) => "7",
                ("4", b) => "5",
                ("5", a) => "7",
                ("5", b) => "6",
                ("6", a) => "7",
                ("6", b) => "1",
                ("7", a) => "7",
                ("7", b) => "7",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1).mingeno

    @test min1.start == "1/4"
    @test length(min1.links) == 8
    @test min1.ones == Set(["1/4", "3/6", "7/"])
    @test min1.zeros == Set(["2/5"])
    @test min1.links[("1/4", a)] == "7/"
    @test min1.links[("1/4", b)] == "2/5"
    @test min1.links[("2/5", a)] == "7/"
    @test min1.links[("2/5", b)] == "3/6"
    @test min1.links[("3/6", a)] == "7/"
    @test min1.links[("3/6", b)] == "1/4"
    @test min1.links[("7/", a)] == "7/"
    @test min1.links[("7/", b)] == "7/"

    # printtest(source, example, max1, min1)
end

@testset "cornell4int" begin
    source = "http://www.cs.cornell.edu/courses/cs2800/2013fa/Handouts/minimization.pdf"
    example = "13.4"
    start = 1
    a = 0
    b = 1
    ones = Set([1, 3, 4, 6, 7])
    zeros = Set([2, 5])

    links = Dict{Tuple{Int, Bool}, Int}(
        (1, a) => 7,
        (1, b) => 2,
        (2, a) => 7,
        (2, b) => 3,
        (3, a) => 7,
        (3, b) => 4,
        (4, a) => 7,
        (4, b) => 5,
        (5, a) => 7,
        (5, b) => 6,
        (6, a) => 7,
        (6, b) => 1,
        (7, a) => 7,
        (7, b) => 7,
    )
    max1 = FSMGeno(start, ones, zeros, links)
    min1, mm = minimize(max1; getmm = true)
    @test min1.start == mm[1]
    @test length(min1.links) == 8
    @test min1.ones == Set([mm[1], mm[3], mm[7]])
    @test min1.zeros == Set([mm[2]])
    newlinks = Dict{Tuple{Int, Bool}, Int}(
        (mm[1], a) => mm[7],
        (mm[1], b) => mm[2],
        (mm[2], a) => mm[7],
        (mm[2], b) => mm[3],
        (mm[3], a) => mm[7],
        (mm[3], b) => mm[1],
        (mm[7], a) => mm[7],
        (mm[7], b) => mm[7],
    )

    @test min1.links == newlinks
end

# 
@testset "neso1" begin
    source = "https://www.youtube.com/watch?v=0XaGAkY09Wc"
    example = "1"
    ikey = IndivKey(:neso1, 1)
    start = "A"
    ones = Set(["A", "B", "C", "D"])
    zeros = Set(["E"])
    links = LinkDict(
                ("A", 0) => "B",
                ("A", 1) => "C",
                ("B", 0) => "B",
                ("B", 1) => "D",
                ("C", 0) => "B",
                ("C", 1) => "C",
                ("D", 0) => "B",
                ("D", 1) => "E",
                ("E", 0) => "B",
                ("E", 1) => "C",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1).mingeno

    @test min1.start == "A/C"
    @test length(min1.links) == 8
    @test min1.ones == Set(["A/C", "B/", "D/"])
    @test min1.zeros == Set(["E/"])
    @test min1.links[("A/C", 0)] == "B/"
    @test min1.links[("A/C", 1)] == "A/C"
    @test min1.links[("B/",  0)] == "B/"
    @test min1.links[("B/",  1)] == "D/"
    @test min1.links[("D/",  0)] == "B/"
    @test min1.links[("D/",  1)] == "E/"
    @test min1.links[("E/",  0)] == "B/"
    @test min1.links[("E/",  1)] == "A/C"

    # printtest(source, example, max1, min1)
end

@testset "neso2" begin
    source = "https://www.youtube.com/watch?v=ex9sPLq5CRg"
    example = "2"
    ikey = IndivKey(:neso2, 1)
    start = "q0"
    ones = Set(["q0", "q1", "q3", "q4", "q5", "q6", "q7"])
    zeros = Set(["q2"])
    links = LinkDict(
                ("q0", 0) => "q1",
                ("q0", 1) => "q5",
                ("q1", 0) => "q6",
                ("q1", 1) => "q2",
                ("q2", 0) => "q0",
                ("q2", 1) => "q2",
                ("q3", 0) => "q2",
                ("q3", 1) => "q6",
                ("q4", 0) => "q7",
                ("q4", 1) => "q5",
                ("q5", 0) => "q2",
                ("q5", 1) => "q6",
                ("q6", 0) => "q6",
                ("q6", 1) => "q4",
                ("q7", 0) => "q6",
                ("q7", 1) => "q2",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1, doprune=true).mingeno

    @test min1.start == "q0/q4"
    @test length(min1.links) == 10
    @test min1.ones == Set(["q0/q4", "q6/", "q1/q7", "q5/"])
    @test min1.zeros == Set(["q2/"])
    @test min1.links[("q0/q4", 0)] == "q1/q7"
    @test min1.links[("q0/q4", 1)] == "q5/"
    @test min1.links[("q6/",   0)] == "q6/"
    @test min1.links[("q6/",   1)] == "q0/q4"
    @test min1.links[("q1/q7", 0)] == "q6/"
    @test min1.links[("q1/q7", 1)] == "q2/"
    @test min1.links[("q5/",   0)] == "q2/"
    @test min1.links[("q5/",   1)] == "q6/"
    @test min1.links[("q2/",   0)] == "q0/q4"
    @test min1.links[("q2/",   1)] == "q2/"
end

@testset "neso3" begin
    source = "https://www.youtube.com/watch?v=DV8cZp-2VmM"
    example = "3"
    ikey = IndivKey(:neso3, 1)
    start = "A"
    ones = Set(["A", "B", "F"])
    zeros = Set(["C", "D", "E"])
    links = LinkDict(
                ("A", 0) => "B",
                ("A", 1) => "C",
                ("B", 0) => "A",
                ("B", 1) => "D",
                ("C", 0) => "E",
                ("C", 1) => "F",
                ("D", 0) => "E",
                ("D", 1) => "F",
                ("E", 0) => "E",
                ("E", 1) => "F",
                ("F", 0) => "F",
                ("F", 1) => "F",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1, doprune=true).mingeno

    @test min1.start == "A/B"
    @test length(min1.links) == 6
    @test min1.ones == Set(["A/B", "F/"])
    @test min1.zeros == Set(["C/D/E"])
    @test min1.links[("A/B",   0)] == "A/B"
    @test min1.links[("A/B",   1)] == "C/D/E"
    @test min1.links[("F/",    0)] == "F/"
    @test min1.links[("F/",    1)] == "F/"
    @test min1.links[("C/D/E", 0)] == "C/D/E"
    @test min1.links[("C/D/E", 1)] == "F/"
end

@testset "neso4" begin
    source = "https://www.youtube.com/watch?v=kYMqDgB2GbU"
    example = "4"
    ikey = IndivKey(:neso4, 1)
    start = "A"
    ones = Set(["A", "D", "E", "F"])
    zeros = Set(["B", "C", "G"])
    links = LinkDict(
                ("A", 0) => "B",
                ("A", 1) => "C",
                ("B", 0) => "D",
                ("B", 1) => "E",
                ("C", 0) => "E",
                ("C", 1) => "D",
                ("D", 0) => "G",
                ("D", 1) => "G",
                ("E", 0) => "G",
                ("E", 1) => "G",
                ("F", 0) => "D",
                ("F", 1) => "E",
                ("G", 0) => "G",
                ("G", 1) => "G",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1, doprune=true).mingeno

    @test min1.start == "A/"
    @test length(min1.links) == 8
    @test min1.ones == Set(["A/", "D/E"])
    @test min1.zeros == Set(["B/C", "G/"])
    @test min1.links[("A/",  0)] == "B/C"
    @test min1.links[("A/",  1)] == "B/C"
    @test min1.links[("D/E", 0)] == "G/"
    @test min1.links[("D/E", 1)] == "G/"
    @test min1.links[("B/C", 0)] == "D/E"
    @test min1.links[("B/C", 1)] == "D/E"
    @test min1.links[("G/",  0)] == "G/"
    @test min1.links[("G/",  1)] == "G/"
end

@testset "westchester1" begin
    source = "https://www.cs.wcupa.edu/rkline/fcs/dfa-min.html"
    example = "2-20"
    ikey = IndivKey(:westchester1, 1)
    start = "q1"
    ones = Set(["q2", "q4", "q5", "q6"])
    zeros = Set(["q1", "q3"])
    links = LinkDict(
                ("q1", 0) => "q2",
                ("q1", 1) => "q4",
                ("q2", 0) => "q5",
                ("q2", 1) => "q3",
                ("q3", 0) => "q2",
                ("q3", 1) => "q6",
                ("q4", 0) => "q1",
                ("q4", 1) => "q5",
                ("q5", 0) => "q5",
                ("q5", 1) => "q5",
                ("q6", 0) => "q3",
                ("q6", 1) => "q5",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1, doprune=true).mingeno

    @test min1.start == "q1/q3"
    @test length(min1.links) == 8
    @test min1.ones == Set(["q2/", "q4/q6", "q5/"])
    @test min1.zeros == Set(["q1/q3"])
    @test min1.links[("q1/q3", 0)] == "q2/"
    @test min1.links[("q1/q3", 1)] == "q4/q6"
    @test min1.links[("q2/",   0)] == "q5/"
    @test min1.links[("q2/",   1)] == "q1/q3"
    @test min1.links[("q4/q6", 0)] == "q1/q3"
    @test min1.links[("q4/q6", 1)] == "q5/"
    @test min1.links[("q5/",   0)] == "q5/"
    @test min1.links[("q5/",   1)] == "q5/"
end

@testset "odu1" begin
    source = "https://www.cs.odu.edu/~toida/nerzic/390teched/regular/fa/min-fa.html"
    example = "1"
    ikey = IndivKey(:odu1, 1)
    start = "1"
    ones = Set(["2", "3", "4"])
    zeros = Set(["1", "5"])
    links = LinkDict(
                ("1", 0) => "3",
                ("1", 1) => "2",
                ("2", 0) => "4",
                ("2", 1) => "1",
                ("3", 0) => "5",
                ("3", 1) => "4",
                ("4", 0) => "4",
                ("4", 1) => "4",
                ("5", 0) => "3",
                ("5", 1) => "2",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1, doprune=true).mingeno

    @test min1.start == "1/5"
    @test length(min1.links) == 8
    @test min1.ones == Set(["2/", "3/", "4/"])
    @test min1.zeros == Set(["1/5"])
    @test min1.links[("1/5", 0)] == "3/"
    @test min1.links[("1/5", 1)] == "2/"
    @test min1.links[("2/",  0)] == "4/"
    @test min1.links[("2/",  1)] == "1/5"
    @test min1.links[("3/",  0)] == "1/5"
    @test min1.links[("3/",  1)] == "4/"
    @test min1.links[("4/",  0)] == "4/"
    @test min1.links[("4/",  1)] == "4/"
end

@testset "odu2" begin
    source = "https://www.cs.odu.edu/~toida/nerzic/390teched/regular/fa/min-fa.html"
    example = "2"
    ikey = IndivKey(:odu2, 2)
    start = "1"
    ones  = Set(["3"])
    zeros = Set(["1", "2", "4", "5", "6"])
    links = LinkDict(
                ("1", 0) => "2",
                ("1", 1) => "3",
                ("2", 0) => "2",
                ("2", 1) => "4",
                ("3", 0) => "3",
                ("3", 1) => "3",
                ("4", 0) => "6",
                ("4", 1) => "3",
                ("5", 0) => "5",
                ("5", 1) => "3",
                ("6", 0) => "5",
                ("6", 1) => "4",
                )

    max1 = FSMIndiv(ikey, start, ones, zeros, links)
    min1 = minimize(max1, doprune=true).mingeno

    @test min1.start == "1/"
    @test length(min1.links) == 12
    @test min1.ones == Set(["3/"])
    @test min1.zeros == Set(["1/", "2/", "4/", "5/", "6/"])
    @test min1.links[("1/", 0)] == "2/"
    @test min1.links[("1/", 1)] == "3/"
    @test min1.links[("2/", 0)] == "2/"
    @test min1.links[("2/", 1)] == "4/"
    @test min1.links[("3/", 0)] == "3/"
    @test min1.links[("3/", 1)] == "3/"
    @test min1.links[("4/", 0)] == "6/"
    @test min1.links[("4/", 1)] == "3/"
    @test min1.links[("5/", 0)] == "5/"
    @test min1.links[("5/", 1)] == "3/"
    @test min1.links[("6/", 0)] == "5/"
    @test min1.links[("6/", 1)] == "4/"
end

end
