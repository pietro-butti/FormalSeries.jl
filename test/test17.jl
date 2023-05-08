###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    test17.jl
### created: Mon May  8 08:53:01 2023
###                               

using Test, FormalSeries

@testset "tanh(s) = (e^2s-1)/(e^2s+1) [DSeries/Series]" begin

    for s in (DSeries((rand(12,2,3))),Series(tuple(rand(12)...)))

        s1 = (exp(2*s)-1)/(exp(2*s)+1)
        s2 = tanh(s)
        
        for i in 1:7
            @test isapprox(s1.c[i], s2.c[i])
        end
    end
end
