# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/JuliaFEM.jl/blob/master/LICENSE.md

using JuliaFEM
using JuliaFEM.Test

@testset "test continuum 3d linear elasticity with surface load" begin
    nodes = Dict{Int64, Node}(
    1 => [0.0, 0.0, 0.0],
    2 => [1.0, 0.0, 0.0],
    3 => [1.0, 1.0, 0.0],
    4 => [0.0, 1.0, 0.0],
    5 => [0.0, 0.0, 1.0],
    6 => [1.0, 0.0, 1.0],
    7 => [1.0, 1.0, 1.0],
    8 => [0.0, 1.0, 1.0])

    element1 = Element(Hex8, [1, 2, 3, 4, 5, 6, 7, 8])
    element2 = Element(Quad4, [5, 6, 7, 8])
    update!([element1, element2], "geometry", nodes)
    update!([element1], "youngs modulus", 288.0)
    update!([element1], "poissons ratio", 1/3)
    update!([element2], "displacement traction force 3", 288.0)
    update!([element1], "displacement load 3", 576.0)

    elasticity_problem = Problem(Elasticity, "solve continuum block", 3)
    elasticity_problem.properties.finite_strain = false
    push!(elasticity_problem, element1)
    push!(elasticity_problem, element2)

    symxy = Element(Quad4, [1, 2, 3, 4])
    symxz = Element(Quad4, [1, 2, 6, 5])
    symyz = Element(Quad4, [1, 4, 8, 5])
    update!([symxy, symxz, symyz], "geometry", nodes)
    symyz["displacement 1"] = 0.0
    symxz["displacement 2"] = 0.0
    symxy["displacement 3"] = 0.0
    boundary_problem = Problem(Dirichlet, "symmetry boundary conditions", 3, "displacement")
    push!(boundary_problem, symxy, symxz, symyz)

    solver = Solver("solve 3d block")
    push!(solver, elasticity_problem)
    push!(solver, boundary_problem)
    call(solver)

    disp = element1("displacement", [1.0, 1.0, 1.0], 0.0)
    info("displacement at tip: $disp")
    u_expected = 2.0 * [-1/3, -1/3, 1.0]
    @test isapprox(disp, u_expected)
end