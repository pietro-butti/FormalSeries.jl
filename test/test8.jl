using Test, FormalSeries

s = Series(tuple(rand(7)...))

@testset "Getting elements" begin
    ok = true
    for i in 1:7
        ok = ok && isapprox(s.c[i], s[i])
    end
    @test ok
end
