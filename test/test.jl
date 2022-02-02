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

println("zero?:  ", B-S)

t = (1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0)
println(t)
S = Series(t)
println("Series:        ", S)
println("sin(1+x): ", sin(S))
println("cos(1+x): ", cos(S))

t = ntuple(i -> rand() , 10)
S = Series(t)
println("Series:        ", S)
S = cos(S)^2 + sin(S)^2
println("cos^2+sin^2: ", S)

t = ntuple(i -> rand() , 10)
S = Series(t)
Ssq = sqrt(sqrt(S))
S2 = Ssq^4
println("sqrt(sqrt(x))]^4 - x: ", S-S2)
