###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    test16.jl
### created: Wed Aug 24 23:09:33 2022
###                               

using Test, FormalSeries

s = DSeries(abs.(rand(7,2,3)))

sl = s^2
se = sqrt(sl)

@testset "sqrt(s^2) = s [DSeries]" begin
    for i in 1:7
        @test isapprox(se.c[i], s.c[i])
    end
end
