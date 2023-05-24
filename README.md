
# FormalSeries.jl: Simple code for formal series operations

This module implements the operations of power series in one or
several variables
$`x_i`$ truncated to order $`N_i`$
```math 
a_0+a_{11}x_1+a_{12}x_2+\dots+a_{1N_v}x_{N_v}+a_{21}x^2_1+a_{22}x^2_2+a_{2N_v}x^2_{N_v}+
\dots+a_{N_1 1}x^{N_1}_1\,.
```

Note that this implements a form of (ForwardMode) automatic
differentiation.

The basic data structures (`Series` for power series in one variable
and `DSeries` in several variables) is of type `isbits`, which guarantees that
`Array`s of these types can be used in the `GPU`.

## Connection with Automatic differentiation

If we consider a generic function:
```julia
julia> f(x) = sin(x+1.0)/(x^2 + 2.0) * (1.0+x+x^2)/(3.0-x)
```
and evaluates this function with the `Series{Float64,
N}(value,1,0,0,0,0,0,...)`, one gets the Taylor expansion of the function
around `value` up to order `N`:
```julia
julia> xv = Series{Float64, 10}((2.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0));
julia> fv = f(xv)
Series{Float64, 10}((0.1646400094031784, -0.9825112361829045, -1.1289774912180284, -0.8714416587163087, -0.8861222136302846, -0.896482950969445, -0.8932526481078228, -0.8949885517838826, -0.8942345605761967, -0.8944154324342811))
julia> println("First  derivative at x=2: ", fv[2])
First  derivative at x=2: -0.9825112361829045

julia> println("Second derivative at x=2: ", 2*fv[3])
Second derivative at x=2: -2.2579549824360567

julia> ...
```

## Usage

One defines series of a certain `isbits` type with the statement:
```julia
julia> s1 = Series{Float64, 4}((1.0,4.0,2.0,5.0));
julia> s2 = Series{Float64, 4}((1.0,-2.0,3.0,-4.0));
```
then, one can perform operations in the usual way
```julia
julia> s3 = s1*sin(s2)/(1.0+s2) - cos(s1*s2)
Series{Float64, 4}((-0.11956681346419151, 3.2463171257673946, -1.86229218981208, 3.9904007446344094))
```
The multi-dimensional version works in a similar way
```julia
julia> s1 = DSeries([2.1 1.0
                     0.0 0.0]);
julia> s2 = DSeries([3.2 0.0
                     1.0 0.0]);
julia> f(x,y) = cos(x)+x^2*sin(y)/(1+y^2);
julia> f(s1,s2)
DSeries{Tuple{2, 2}, Float64, 4, 2, 4}([-0.5277491270656608 -0.8850217689972577; -0.3786388449709715 -0.36060842378187763])
```
Note that:
```math
f(2.1,3.2) = -0.5277491270656608
```
```math
\frac{\partial f}{\partial x}\Big|_{x=2.1,y=3.2} = -0.8850217689972577
```
```math
\frac{\partial f}{\partial y}\Big|_{x=2.1,y=3.2} = -0.3786388449709715
```
```math
\frac{\partial^2 f}{\partial x\partial y}\Big|_{x=2.1,y=3.2} = -0.36060842378187763
```


## Connection with Automatic differentiation

If we consider a generic function:
```julia
julia> f(x) = sin(x+1.0)/(x^2 + 2.0) * (1.0+x+x^2)/(3.0-x)
```
and evaluates this function with the `Series{Float64,
N}(value,1,0,0,0,0,0,...)`, one gets the Taylor expansion of the function
around `value` up to order `N`:
```julia
julia> xv = Series{Float64, 10}((2.0,1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0));
julia> fv = f(xv)
Series{Float64, 10}((0.1646400094031784, -0.9825112361829045, -1.1289774912180284, -0.8714416587163087, -0.8861222136302846, -0.896482950969445, -0.8932526481078228, -0.8949885517838826, -0.8942345605761967, -0.8944154324342811))
julia> println("First  derivative at x=2: ", fv[2])
First  derivative at x=2: -0.9825112361829045

julia> println("Second derivative at x=2: ", 2*fv[3])
Second derivative at x=2: -2.2579549824360567

julia> ...
```
