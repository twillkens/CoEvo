using Test
using Random
using StableRNGs
using CoEvo
using Primes

include("util.jl")


@testset "GP" begin
@testset "ExprNode" begin
    e = Expr(:call, +, 1, 2)
    n = ExprNode(e)
    @test n.val == (+)
    @test n.children[1].val == 1
    @test n.children[2].val == 2
    @test Expr(n) == e
end

@testset "AddFunc1" begin
    n1 = ExprNode(+)
    n2 = ExprNode(1, n1)
    n3 = ExprNode(2, n1)
    n1.children = [n2, n3]
    nodes = Set([n1, n2, n3])
    funcs = Set([n1])
    terms = Set([n2, n3])
    geno = GPGeno(n1, nodes, funcs, terms)

    target = n1
    newfunc = ExprNode(-)
    newchildren = [n1, ExprNode(3)]

    mutgeno = addfunc(geno, target, newfunc, newchildren)

    t1 = ExprNode(-)
    t2 = ExprNode(+, t1)
    t3 = ExprNode(1, t2)
    t4 = ExprNode(2, t2)
    t5 = ExprNode(3, t1)    
    t1.children = [t2, t5]
    t2.children = [t3, t4]
    nodes = Set([t1, t2, t3, t4, t5])
    funcs = Set([t1, t2])
    terms = Set([t3, t4, t5])
    testgeno = GPGeno(t1, nodes, funcs, terms)

    @test Expr(mutgeno) == Expr(testgeno)
    
end

@testset "AddFunc2" begin
    n1 = ExprNode(+)
    n2 = ExprNode(-, n1)
    n3 = ExprNode(*, n1)
    n1.children = [n2, n3]
    n4 = ExprNode(1, n2)
    n5 = ExprNode(2, n2)
    n2.children = [n4, n5]
    n6 = ExprNode(3, n3)
    n7 = ExprNode(4, n3)
    n3.children = [n6, n7]
    nodes = Set([n1, n2, n3, n4, n5, n6, n7])
    funcs = Set([n1, n2, n3])
    terms = Set([n4, n5, n6, n7])
    geno = GPGeno(n1, nodes, funcs, terms)

    rng = StableRNG(42)
    m = GPMutator()

    for _ in 1:10
        testgeno = addfunc(rng, m, geno)
        @test length(testgeno.funcs) == 4
        println("AddFunc2: ", Expr(testgeno.root))
    end
end

@testset "RMFunc1" begin
    n1 = ExprNode(+)
    n2 = ExprNode(-, n1)
    n3 = ExprNode(*, n1)
    n1.children = [n2, n3]
    n4 = ExprNode(0, n2)
    n5 = ExprNode(1, n2)
    n2.children = [n4, n5]
    n6 = ExprNode(2, n3)
    n7 = ExprNode(3, n3)
    n3.children = [n6, n7]
    nodes = Set([n1, n2, n3, n4, n5, n6, n7])
    funcs = Set([n1, n2, n3])
    terms = Set([n4, n5, n6, n7])
    geno = GPGeno(n1, nodes, funcs, terms)

    testgeno = rmfunc(geno, n1, n2, [Pair(n3, n4)])

    t1 = ExprNode(-)
    t2 = ExprNode(*, t1)
    t3 = ExprNode(2, t2)
    t4 = ExprNode(3, t2)
    t5 = ExprNode(1, t1)
    t1.children = [t2, t5]
    t2.children = [t3, t4]
    @test Expr(testgeno.root) == Expr(t1)
end

@testset "RMFunc2" begin
    n1 = ExprNode(+)
    n2 = ExprNode(-, n1)
    n3 = ExprNode(*, n1)
    n1.children = [n2, n3]
    n4 = ExprNode(0, n2)
    n5 = ExprNode(1, n2)
    n2.children = [n4, n5]
    n6 = ExprNode(2, n3)
    n7 = ExprNode(3, n3)
    n3.children = [n6, n7]
    nodes = Set([n1, n2, n3, n4, n5, n6, n7])
    funcs = Set([n1, n2, n3])
    terms = Set([n4, n5, n6, n7])
    geno = GPGeno(n1, nodes, funcs, terms)

    rng = StableRNG(1234)
    m = GPMutator()

    for _ in 1:10
        testgeno = rmfunc(rng, m, geno)
        @test length(testgeno.funcs) == 2
        println("RMFunc2: ", Expr(testgeno.root))
    end
end

@testset "SwapNode1" begin
    n1 = ExprNode(+)
    n2 = ExprNode(-, n1)
    n3 = ExprNode(*, n1)
    n1.children = [n2, n3]
    n4 = ExprNode(0, n2)
    n5 = ExprNode(1, n2)
    n2.children = [n4, n5]
    n6 = ExprNode(2, n3)
    n7 = ExprNode(3, n3)
    n3.children = [n6, n7]
    nodes = Set([n1, n2, n3, n4, n5, n6, n7])
    funcs = Set([n1, n2, n3])
    terms = Set([n4, n5, n6, n7])
    geno = GPGeno(n1, nodes, funcs, terms)


    mutgeno = swapnode(geno, n2, n3)

    t1 = ExprNode(+)
    t2 = ExprNode(*, t1)
    t3 = ExprNode(-, t1)
    t4 = ExprNode(0, t3)
    t5 = ExprNode(1, t3)
    t6 = ExprNode(2, t2)
    t7 = ExprNode(3, t2)
    t1.children = [t2, t3]
    t2.children = [t6, t7]
    t3.children = [t4, t5]
    nodes = Set([t1, t2, t3, t4, t5, t6, t7])
    funcs = Set([t1, t2, t3])
    terms = Set([t4, t5, t6, t7])
    testgeno = GPGeno(t1, nodes, funcs, terms)

    @test Expr(mutgeno) == Expr(testgeno)
end

@testset "SwapNode2" begin
    n1 = ExprNode(*)
    n2 = ExprNode(-, n1)
    n3 = ExprNode(+, n1)
    n1.children = [n2, n3]
    n4 = ExprNode(1, n2)
    n5 = ExprNode(2, n2)
    n2.children = [n4, n5]
    n6 = ExprNode(3, n3)
    n7 = ExprNode(4, n3)
    n3.children = [n6, n7]
    nodes = Set([n1, n2, n3, n4, n5, n6, n7])
    funcs = Set([n1, n2, n3])
    terms = Set([n4, n5, n6, n7])
    geno = GPGeno(n1, nodes, funcs, terms)

    rng = StableRNG(42)
    m = GPMutator()

    for n in 1:10
        mutgeno = swapnode(rng, m, geno)
        @test length(mutgeno.funcs) == 3
        println("SwapNode2: ", Expr(mutgeno.root))
    end

    rng = StableRNG(42)
    m = GPMutator()
    println("--------------")
    for n in 1:10
        mutgeno = swapnode(rng, m, geno)
        @test length(mutgeno.funcs) == 3
        println("SwapNode2: ", Expr(mutgeno.root))
    end
end

@testset "Simulate1" begin
    n1 = ExprNode(+)
    n2 = ExprNode(1, n1)
    n3 = ExprNode(1, n1)
    n1.children = [n2, n3]
    expr1 = Expr(n1)
    expr2 = deepcopy(expr1)
    tape1, tape2 = simulate(3, expr1, expr2)
    @test tape1 == tape2
    @test tape1 == [2, 2, 2]
end

@testset "Simulate with read" begin
    n1 = ExprNode(+)
    n2 = ExprNode(:read, n1)
    n3 = ExprNode(1, n1)
    n1.children = [n2, n3]
    expr1 = Expr(n1)
    expr2 = copy(expr1)
    tape1, tape2 = simulate(3, expr1, expr2)
    @test tape1 == tape2
    @test tape1 == [1, 2, 3]
end

@testset "Simulate with read asymmetric" begin
    n1 = ExprNode(+)
    n2 = ExprNode(:read, n1)
    n3 = ExprNode(1, n1)
    n1.children = [n2, n3]
    expr1 = Expr(n1)
    n1 = ExprNode(+)
    n2 = ExprNode(:read, n1)
    n3 = ExprNode(:read, n1)
    n1.children = [n2, n3]
    expr2 = Expr(n1)
    tape1, tape2 = simulate(100, expr1, expr2, radianshift)
    println(tape1)
    println(tape2)
end

end