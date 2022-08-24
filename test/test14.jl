###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    test6.jl
### created: Mon Aug 22 23:27:41 2022
###                               

using Test, FormalSeries

s = DSeries(abs.(randn(3,4,6))) 

se = exp(s)
sl = log(se)

@testset "e^(log(s)) = s [DSeries]" begin
    for i in eachindex(se.c)
        @test isapprox(sl.c[i], s.c[i])
    end
end
