###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    runtests.jl
### created: Thu Jun 30 16:17:07 2022
###                               

using Test

@testset verbose = true "one-dimensional series" begin
    include("test1.jl")
    include("test2.jl")
    include("test3.jl")
    include("test4.jl")
    include("test5.jl")
    include("test6.jl")
    include("test7.jl")
    include("test8.jl")
    include("test18.jl")
    include("test19.jl")
    include("test20.jl")
end

##
# Test set for d-dimansional series
##

@testset verbose = true "d-dimensional series" begin
    include("test9.jl")
    include("test10.jl")
    include("test11.jl")
    include("test12.jl")
    include("test13.jl")
    include("test14.jl")
    include("test15.jl")
    include("test16.jl")
    include("test17.jl")
end
