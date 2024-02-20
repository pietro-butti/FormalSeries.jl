
using Test, FormalSeries

p3(x) = 1.0+2*x+5*x^3
p1(x) = 1.0+2*x

@testset "Evaluating Series" begin
    s = Series((1.0, 2.0, 0.0, 5.0))

    @test isapprox(p3(9.3),s(9.3))
    @test isapprox(1.0,s(9.3, 0))
    @test isapprox(p1(9.3),s(9.3, 1))
    @test isapprox(p1(9.3),s(9.3, 2))
end
