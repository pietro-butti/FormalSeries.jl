###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    test10.jl
### created: Mon Aug 22 18:15:51 2022
###                               

using Test, FormalSeries

A = randn(3,4,6)
s = DSeries(A)

@testset "Add/multiplication" begin

    s2 = zero(s)
    for i in 1:16
        s2 = s2 + s
    end
    s1 = s*16
    
    
    for i in 1:length(CartesianIndices(A))
        @test isapprox(s1[i], s2[i])
    end
end

