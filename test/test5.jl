###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    test5.jl
### created: Mon Aug 22 23:24:53 2022
###                               

using Test, FormalSeries

s = Series(tuple(rand(7)...))

ssin = sin(s)
scos = cos(s)
maybe1 = ssin^2 + scos^2

@testset "sin^2+cos^2 = 1" begin
    ok = isapprox(maybe1.c[1], 1.0)
    for i in 2:7
        ok = ok && isapprox(maybe1.c[i], 0.0, atol=1.0E-14, rtol=0.0)
    end
    @test ok
end
