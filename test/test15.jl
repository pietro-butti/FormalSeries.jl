###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    test15.jl
### created: Wed Aug 24 17:30:03 2022
###                               

using Test, FormalSeries

s1 = DSeries(randn(5,8,3))
s2 = DSeries(randn(5,8,3)) + 10.0

@testset "Division of series [DSeries]" begin
    s = s1/s2
    s = s*s2

    for i in eachindex(s.c)
        @test isapprox(s.c[i], s1.c[i])
    end
end
