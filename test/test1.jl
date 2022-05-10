
using Test, FormalSeries

s1 = Series((1.0,4.0,2.0,5.0))
s2 = Series((0.4,1.0,0.5,1.0))

@testset "Testing basic oprations" begin
    s = s1+s2
    @test isapprox(s.c[1], s1.c[1]+s2.c[1]) && isapprox(s.c[2], s1.c[2]+s2.c[2]) && isapprox(s.c[3], s1.c[3]+s2.c[3]) && isapprox(s.c[4], s1.c[4]+s2.c[4])
    
    s = s1-s2
    @test isapprox(s.c[1], s1.c[1]-s2.c[1]) && isapprox(s.c[2], s1.c[2]-s2.c[2]) && isapprox(s.c[3], s1.c[3]-s2.c[3]) && isapprox(s.c[4], s1.c[4]-s2.c[4])
    
    s = s1+3.0
    @test isapprox(s.c[1], s1.c[1]+3.0) && isapprox(s.c[2], s1.c[2]) && isapprox(s.c[3], s1.c[3]) && isapprox(s.c[4], s1.c[4])
    
    s = s1-3.0
    @test isapprox(s.c[1], s1.c[1]-3.0) && isapprox(s.c[2], s1.c[2]) && isapprox(s.c[3], s1.c[3]) && isapprox(s.c[4], s1.c[4])
end
