import Pkg

Pkg.activate("/home/alberto/code/julia/FormalSeries/")
using FormalSeries


t = ntuple(i -> i<9 ? i*2.0 : 0.0 , 3)
t = ntuple(i -> rand() , 10)
println(t)
S = Series(t)
println("Series: ", S)

A = log(S)
println("log:    ", A)

B = exp(A)
println("exp:    ", B)
