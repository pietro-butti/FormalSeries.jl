
using Test, FormalSeries

@testset "Broadcasting as scalar" begin

    s1 = Series((1.0, 0.0))
    s2 = Series((2.0, 1.0))

    s3_1 = [s1, s1] .+ s2
    s3_2 = [s2, s2] .+ s1

    @test s3_1 == s3_2
    @test s3_1[1] == s3_1[2]
end
