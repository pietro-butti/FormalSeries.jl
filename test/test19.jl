
using Test, FormalSeries

@testset "isnan isinf" begin

    s1 = Series((1.0, 1.0))
    snan = Series((0.0, NaN))

    @test isnan(snan + s1)
    @test isinf(s1 / 0.0)
end
