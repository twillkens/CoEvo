using Test
using Random
using StableRNGs
using CoEvo

@testset "GNARL" begin
    
@testset "get_req" begin
    in_pos = Set([-2.0, -1.0, 0.0])
    hidden_pos = Set([0.5, 0.75])
    out_pos = Set([1.0, 2.0])
    conn_tups = Set([(-2.0, 0.5), (0.5, 1.0), (0.75, 2.0), (0.75, 0.75)])
    @test get_req(in_pos, hidden_pos, out_pos, conn_tups, true) == Set([0.5])
    @test get_req(in_pos, hidden_pos, out_pos, conn_tups, false) == Set([0.5, 0.75])
end

@testset "minimize_pos" begin
    in_pos = Set([-2.0, -1.0, 0.0])
    hidden_pos = Set([0.1, 0.2, 0.3, 0.4, 0.5, 0.6])
    out_pos = Set([1.0, 2.0])
    conn_tups = Set{Tuple{Float64, Float64}}([
        (-2.0, 0.2),
        (0.0, 0.4),
        (0.2, 0.3),
        (0.2, 1.0),
        (0.3, 0.2),
        (0.3, 2.0),
        (0.4, 0.6),
        (0.5, 0.5),
        (0.5, 2.0),
        (0.6, 0.4),
    ])
    req_pos = get_req(in_pos, hidden_pos, out_pos, conn_tups)
    @test req_pos == Set([0.2, 0.3])
    all_pos = union(in_pos, req_pos, out_pos)

    req_conns = Set(filter(
        x -> x[1] in all_pos && x[2] in all_pos, 
        collect(conn_tups)
    ))
    @test req_conns == Set([
        (-2.0, 0.2),
        (0.2, 0.3),
        (0.3, 0.2),
        (0.2, 1.0),
        (0.3, 2.0)
    ])

    
end

@testset "minimize_geno" begin
    g = GNARLGeno(
        [GNARLNodeGene(1, -2.0), GNARLNodeGene(2, -1.0), GNARLNodeGene(3, 0.0)],
        [
            GNARLNodeGene(4, 0.1), GNARLNodeGene(5, 0.2), GNARLNodeGene(6, 0.3), 
            GNARLNodeGene(7, 0.4), GNARLNodeGene(8, 0.5), GNARLNodeGene(9, 0.6)]
        ,
        [GNARLNodeGene(10, 1.0), GNARLNodeGene(11, 2.0)],
        [
            GNARLConnectionGene(12, (-2.0, 0.2), 0.0), 
            GNARLConnectionGene(13, (0.0, 0.4), 0.0),
            GNARLConnectionGene(14, (0.2, 0.3), 0.0),
            GNARLConnectionGene(15, (0.2, 1.0), 0.0),
            GNARLConnectionGene(16, (0.3, 0.2), 0.0),
            GNARLConnectionGene(17, (0.3, 2.0), 0.0),
            GNARLConnectionGene(18, (0.4, 0.6), 0.0),
            GNARLConnectionGene(19, (0.5, 0.5), 0.0),
            GNARLConnectionGene(20, (0.5, 2.0), 0.0),
            GNARLConnectionGene(21, (0.6, 0.4), 0.0)
        ]
    )

    g2 = minimize(g)

    @test g2.inputs == [GNARLNodeGene(1, -2.0), GNARLNodeGene(2, -1.0), GNARLNodeGene(3, 0.0)]
    @test g2.hidden == [GNARLNodeGene(5, 0.2), GNARLNodeGene(6, 0.3)]
    @test g2.outputs == [GNARLNodeGene(10, 1.0), GNARLNodeGene(11, 2.0)]
    @test g2.connections == [
        GNARLConnectionGene(12, (-2.0, 0.2), 0.0), 
        GNARLConnectionGene(14, (0.2, 0.3), 0.0),
        GNARLConnectionGene(15, (0.2, 1.0), 0.0),
        GNARLConnectionGene(16, (0.3, 0.2), 0.0),
        GNARLConnectionGene(17, (0.3, 2.0), 0.0)
    ]
end


end