using LingPred
using Test

verbose = false

function printsim(testname,
                  fsm1, fsm2,
                  goal1, goal2,
                  states1, states2,
                  scores1, scores2,
                  loop1, loop2,
                  score1, score2)
    if verbose
        println("---------")
        println("Test: $(testname)\n")
        println("FSM1")
        printFSM(fsm1)
        println()
        println("FSM2")
        printFSM(fsm2)
        println()
        println("FSM1 Goal: ", goal1)
        println("FSM2 Goal: ", goal2)
        println("FSM1 State Trajectory: ", states1)
        println("FSM2 State Trajectory: ", states2)
        println("FSM1 All Scores: ", scores1)
        println("FSM2 All Scores: ", scores2)
        println("FSM1 Loop Scores: ", loop1)
        println("FSM2 Loop Scores: ", loop2)
        println("FSM1 Final Score: ", score1)
        println("FSM2 Final Score: ", score2)
    end
    
end

@testset "Simulate" begin

@testset "simple" begin
    testname = "Simple"

    key = "A"
    start = "A0"
    curr = "A0"
    ones = Set(["A1"])
    zeros = Set(["A0"])
    links = LinkDict(
                ("A0", 0)  => "A0",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A0",
                ("A1", 1)  => "A1",
                )
    fsm1 = FSM(key, false, start, ones, zeros, links)
    goal1 = "coop"
    a1 = FSMAgent(fsm1, goal1)

    key = "B"
    start = "B0"
    curr = "B0"
    ones = Set(["B1"])
    zeros = Set(["B0"])
    links = LinkDict(
                ("B0", 0)  => "B1",
                ("B0", 1)  => "B0",
                ("B1", 0)  => "B1",
                ("B1", 1)  => "B0",
                )
    fsm2 = FSM(key, false, start, ones, zeros, links)
    goal2 = "coop"
    a2 = FSMAgent(fsm2, goal2)

    scores, traj1, traj2, loop1, loop2, states1, states2 = simulate_verbose(a1, a2)
    score1 = scores[(a1.key, a2.key)]
    score2 = scores[(a2.key, a1.key)]
    @test traj1 == [0, 0, 1, 1, 0]
    @test traj2 == [0, 1, 1, 0, 0]
    @test loop1 == [0, 0, 1, 1]
    @test loop2 == [0, 1, 1, 0]
    @test states1 == ["A0", "A0", "A1", "A1", "A0"]
    @test states2 == ["B0", "B1", "B1", "B0", "B0"]
    @test scores[(a1.key, a2.key)] ≈ 0.5
    @test scores[(a2.key, a1.key)] ≈ 0.5

    printsim(testname, fsm1, fsm2, goal1, goal2, states1, states2,
             traj1, traj2, loop1, loop2, score1, score2)
end

@testset "coop1" begin
    testname = "Coop1"
    key = "A"
    start = "A0"
    curr = "A0"
    zeros = Set(["A0"])
    ones = Set(["A1"])
    links = LinkDict(
                ("A0", 0)  => "A1",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A1",
                ("A1", 1)  => "A0",
                )
    fsm1 = FSM(key, false, start, ones, zeros, links)
    goal1 = "coop"
    a1 = FSMAgent(fsm1, goal1)

    key = "B"
    start = "B0"
    curr = "B0"
    zeros = Set(["B0"])
    ones = Set(["B1"])
    links = LinkDict(
                ("B0", 0)  => "B0",
                ("B0", 1)  => "B1",
                ("B1", 0)  => "B0",
                ("B1", 1)  => "B1",
                )
    fsm2 = FSM(key, false, start, ones, zeros, links)
    goal2 = "coop"
    a2 = FSMAgent(fsm2, goal2)

    scores, traj1, traj2, loop1, loop2, states1, states2 = simulate_verbose(a1, a2)
    score1 = scores[(a1.key, a2.key)]
    score2 = scores[(a2.key, a1.key)]
    @test traj1 == [0, 1, 1, 0, 1]
    @test traj2 == [0, 0, 1, 1, 0]
    @test loop1 == [1, 1, 0]
    @test loop2 == [0, 1, 1]
    @test states1 == ["A0", "A1", "A1", "A0", "A1"]
    @test states2 == ["B0", "B0", "B1", "B1", "B0"]
    @test scores[(a1.key, a2.key)] ≈ 1/3
    @test scores[(a2.key, a1.key)] ≈ 1/3

    printsim(testname, fsm1, fsm2, goal1, goal2, states1, states2,
             traj1, traj2, loop1, loop2, score1, score2)
end

@testset "comp1" begin
    testname = "Comp1"
    key = "A"
    start = "A0"
    curr = "A0"
    zeros = Set(["A0"])
    ones = Set(["A1"])
    links = LinkDict(
                ("A0", 0)  => "A1",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A1",
                ("A1", 1)  => "A0",
                )
    fsm1 = FSM(key, false, start, ones, zeros, links)
    goal1 = "coop"
    a1 = FSMAgent(fsm1, goal1)

    key = "B"
    start = "B0"
    curr = "B0"
    zeros = Set(["B0"])
    ones = Set(["B1"])
    links = LinkDict(
                ("B0", 0)  => "B0",
                ("B0", 1)  => "B1",
                ("B1", 0)  => "B0",
                ("B1", 1)  => "B1",
                )
    fsm2 = FSM(key, false, start, ones, zeros, links)
    goal2 = "comp"
    a2 = FSMAgent(fsm2, goal2)

    scores, traj1, traj2, loop1, loop2, states1, states2 = simulate_verbose(a1, a2)
    score1 = scores[(a1.key, a2.key)]
    score2 = scores[(a2.key, a1.key)]
    @test traj1 == [0, 1, 1, 0, 1]
    @test traj2 == [0, 0, 1, 1, 0]
    @test loop1 == [1, 1, 0]
    @test loop2 == [0, 1, 1]
    @test states1 == ["A0", "A1", "A1", "A0", "A1"]
    @test states2 == ["B0", "B0", "B1", "B1", "B0"]
    @test scores[(a1.key, a2.key)] ≈ 1/3
    @test scores[(a2.key, a1.key)] ≈ 2/3

    printsim(testname, fsm1, fsm2, goal1, goal2, states1, states2,
             traj1, traj2, loop1, loop2, score1, score2)
end

@testset "coop2" begin
    testname = "Coop2"
    key = "A"
    start = "a"
    curr = "a"
    ones = Set(["b", "c"])
    zeros = Set(["a"])
    links = LinkDict(
                ("a", 0)  => "a",
                ("a", 1)  => "b",
                ("b", 0)  => "c",
                ("b", 1)  => "b",
                ("c", 0)  => "c",
                ("c", 1)  => "b",
                )
    fsm1 = FSM(key, false, start, ones, zeros, links)
    goal1 = "coop"
    a1 = FSMAgent(fsm1, goal1)

    key = "B"
    start = "a"
    curr = "a"
    ones = Set(["a", "c"])
    zeros = Set(["b"])
    links = LinkDict(
                ("a", 0)  => "a",
                ("a", 1)  => "b",
                ("b", 0)  => "b",
                ("b", 1)  => "c",
                ("c", 0)  => "a",
                ("c", 1)  => "a",
                )
    fsm2 = FSM(key, false, start, ones, zeros, links)
    goal2 = "coop"
    a2 = FSMAgent(fsm2, goal2)

    scores, traj1, traj2, loop1, loop2, states1, states2 = simulate_verbose(a1, a2)
    score1 = scores[(a1.key, a2.key)]
    score2 = scores[(a2.key, a1.key)]
    @test traj1 == [0, 1, 1, 1, 1]
    @test traj2 == [1, 1, 0, 1, 1]
    @test loop1 == [1, 1, 1]
    @test loop2 == [1, 0, 1]
    @test states1 == ["a", "b", "b", "c", "b"]
    @test states2 == ["a", "a", "b", "c", "a"]
    @test scores[(a1.key, a2.key)] ≈ 2/3
    @test scores[(a2.key, a1.key)] ≈ 2/3

    printsim(testname, fsm1, fsm2, goal1, goal2, states1, states2,
             traj1, traj2, loop1, loop2, score1, score2)
end

@testset "comp2" begin
    testname = "Comp2"
    key = "A"
    start = "a"
    curr = "a"
    ones = Set(["b", "c"])
    zeros = Set(["a"])
    links = LinkDict(
                ("a", 0)  => "a",
                ("a", 1)  => "b",
                ("b", 0)  => "c",
                ("b", 1)  => "b",
                ("c", 0)  => "c",
                ("c", 1)  => "b",
                )
    fsm1 = FSM(key, false, start, ones, zeros, links)
    goal1 = "coop"
    a1 = FSMAgent(fsm1, goal1)

    key = "B"
    start = "a"
    ones = Set(["a", "c"])
    zeros = Set(["b"])
    links = LinkDict(
                ("a", 0)  => "a",
                ("a", 1)  => "b",
                ("b", 0)  => "b",
                ("b", 1)  => "c",
                ("c", 0)  => "a",
                ("c", 1)  => "a",
                )
    fsm2 = FSM(key, false, start, ones, zeros, links)
    goal2 = "comp"
    a2 = FSMAgent(fsm2, goal2)

    scores, traj1, traj2, loop1, loop2, states1, states2 = simulate_verbose(a1, a2)
    score1 = scores[(a1.key, a2.key)]
    score2 = scores[(a2.key, a1.key)]
    @test traj1 == [0, 1, 1, 1, 1]
    @test traj2 == [1, 1, 0, 1, 1]
    @test loop1 == [1, 1, 1]
    @test loop2 == [1, 0, 1]
    @test states1 == ["a", "b", "b", "c", "b"]
    @test states2 == ["a", "a", "b", "c", "a"]
    @test scores[(a1.key, a2.key)] ≈ 2/3
    @test scores[(a2.key, a1.key)] ≈ 1/3

    printsim(testname, fsm1, fsm2, goal1, goal2, states1, states2,
             traj1, traj2, loop1, loop2, score1, score2)
end

end