using LingPred
using Test

function dummyA(key::String)
    start = "A0"
    zeros = Set(["A0"])
    ones = Set(["A1"])
    links = LinkDict(
                ("A0", 0)  => "A1",
                ("A0", 1)  => "A1",
                ("A1", 0)  => "A1",
                ("A1", 1)  => "A0",
                )
    fsm = FSM(key, false, start, ones, zeros, links)
    FSMIndividual(key, fsm, minimize(fsm), DiscoRecord())
end

function dummyB(key::String)
    start = "B0"
    zeros = Set(["B0"])
    ones = Set(["B1"])
    links = LinkDict(
                ("B0", 0)  => "B0",
                ("B0", 1)  => "B1",
                ("B1", 0)  => "B0",
                ("B1", 1)  => "B1",
                )
    fsm = FSM(key, false, start, ones, zeros, links)
    FSMIndividual(key, fsm, minimize(fsm), DiscoRecord())
end


@testset "Evaluation" begin
    cfg_filename = joinpath("cfgs", "serial", "roulette", "mixed.yaml")
    cfg = get_config(cfg_filename)
    e = Evolution(cfg)

    hostindivs = [dummyA("host-$(i)") for i in 1:50]
    paraindivs = [dummyB("parasite-$(i)") for i in 1:50]
    symbindivs = [dummyB("symbiote-$(i)") for i in 1:50]

    e.pops["host"].indivs = hostindivs
    e.pops["parasite"].indivs = paraindivs
    e.pops["symbiote"].indivs = symbindivs

    evaluate!(e)

    for indiv in e.pops["host"].indivs
        calcfitness!(indiv)
        @test length(indiv.disco.tests) == 100
        @test indiv.disco.avg_fitness ≈ 1/3
    end

    for indiv in e.pops["parasite"].indivs
        calcfitness!(indiv)
        @test length(indiv.disco.tests) == 50
        @test indiv.disco.avg_fitness ≈ 2/3
    end

    for indiv in e.pops["symbiote"].indivs
        calcfitness!(indiv)
        @test length(indiv.disco.tests) == 50
        @test indiv.disco.avg_fitness ≈ 1/3
    end
end