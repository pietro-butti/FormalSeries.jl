###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    FormalSeriesTypes.jl
### created: Sun Sep 26 22:08:18 2021
###                               

##
# Cheat to make AbstarctSeries work with AD
## 
abstract type AbstractSeries end#<: Real end

struct Series{T,N} <: AbstractSeries
    c::NTuple{N,T}
end
Series{T,N}(x::Series{T,N}) where {T,N} = x

# Non-allocating version of ntuple function
@generated function genseries(::Type{Series{T,N}}, f) where {T,N}
    vars = Vector{Expr}(undef, N)
    for i in 1:N
        vars[i] = Expr(:call, :(f), i)
    end
    t = Expr(:tuple,  [vars[i] for i = 1:N]...)
    pack = :(Series{T, N}($t))
    
    return Expr(
	:block,
	:(return $pack)
    )
end

# Evaluation of series
function (s::Series{T,N})(x) where {T,N}
    
    v = s.c[N]*x + s.c[N-1]
    for k in N-2:-1:1
        v = v*x + s.c[k]
    end

    return v
end 


import Base.one, Base.zero, Base.conj, Base.imag, Base.real
Base.one(::Type{Series{T,N}})   where {T,N} = genseries(Series{T,N}, i -> i == 1 ? one(T)  : zero(T))
Base.one(s::Series{T,N})        where {T,N} = genseries(Series{T,N}, i -> i == 1 ? one(T)  : zero(T))
Base.zero(::Type{Series{T,N}})  where {T,N} = genseries(Series{T,N}, i -> zero(T))
Base.zero(s::Series{T,N})       where {T,N} = genseries(Series{T,N}, i -> zero(T))
Base.conj(x::Series{T,N})       where {T,N} = genseries(Series{T,N}, i -> conj(x.c[i]))
Base.imag(x::Series{T,N})       where {T,N} = genseries(Series{T,N}, i -> imag(x.c[i]))
Base.real(x::Series{T,N})       where {T,N} = genseries(Series{T,N}, i -> real(x.c[i]))

import Base.:+, Base.:-, Base.:*, Base.:/, Base.:^

Base.:+(s1::Series{T,N})                  where {T,N} = s1
Base.:+(s1::Series{T,N}, s2::Series{T,N}) where {T,N} = genseries(Series{T,N}, i -> s1.c[i] + s2.c[i])
Base.:+(s1::Series{T,N}, s2::Number)      where {T,N} = genseries(Series{T,N}, i -> i == 1 ? s1.c[1] + s2 : s1.c[i])
Base.:+(s2::Number, s1::Series{T,N})      where {T,N} = genseries(Series{T,N}, i -> i == 1 ? s1.c[1] + s2 : s1.c[i])

Base.:-(s1::Series{T,N})                  where {T,N} = genseries(Series{T,N}, i -> -s1.c[i])
Base.:-(s1::Series{T,N}, s2::Series{T,N}) where {T,N} = genseries(Series{T,N}, i -> s1.c[i] - s2.c[i])
Base.:-(s1::Series{T,N}, s2::Number)      where {T,N} = genseries(Series{T,N}, i -> i == 1 ?  s1.c[1] - s2 :  s1.c[i])
Base.:-(s2::Number, s1::Series{T,N})      where {T,N} = genseries(Series{T,N}, i -> i == 1 ? -s1.c[1] + s2 : -s1.c[i])

function Base.:*(s1::Series{T,N}, s2::Series{T,N}) where {T,N}

    @inline function mul(i)
        c = s1.c[1]*s2.c[i]
        @inbounds for k in 2:i
            c = c + s1.c[k]*s2.c[i-k+1]
        end
        return c
    end
    
    return genseries(Series{T,N},mul)
end
Base.:*(s1::Series{T,N}, s2::Number)      where {T,N} = genseries(Series{T,N}, i -> s1.c[i]*s2)
Base.:*(s2::Number, s1::Series{T,N})      where {T,N} = genseries(Series{T,N}, i -> s2*s1.c[i])

@generated function Base.:/(b::Series{T,N},a::Series{T,N}) where {T,N} 
    vars = Vector{Expr}(undef, N)
    expr = Expr(:call,:(/),:(b.c[1]),:(a.c[1]))
    vars[1] = :($(Symbol("c_1")) = $expr)
    for i in 2:N
	ex = Expr(
	    :call,
	    :+,
	    [:( a.c[$i-$k+1] * $(Symbol("c_$(k)")) ) for k in 1:i-1]...
	        )
        
        ex2 = Expr(:call, :-, :(b.c[$i]), ex)
        ex3 = Expr(:call, :/, ex2, :(a.c[1]))

	vars[i] = :($(Symbol("c_$(i)")) = $ex3)
    end

    t = Expr(:tuple,  [Symbol("c_$(i)") for i = 1:N]...)
    pack = :(Series{T, N}($t))


    return Expr(
	:block,
	vars...,
	:(return $pack)
    )
end

Base.:/(s1::Series{T,N}, s2::Number)      where {T,N} = genseries(Series{T,N},i -> s1.c[i]/s2)
@generated function Base.:/(b::Number,a::Series{T,N}) where {T,N} 
    vars = Vector{Expr}(undef, N)
    expr = Expr(:call,:(/),:(b),:(a.c[1]))
    vars[1] = :($(Symbol("c_1")) = $expr)
    for i in 2:N
	ex = Expr(
	    :call,
	    :+,
	    [:( a.c[$i-$k+1] * $(Symbol("c_$(k)")) ) for k in 1:i-1]...
	        )
        
        ex2 = Expr(:call, :-, ex)
        ex3 = Expr(:call, :/, ex2, :(a.c[1]))

	vars[i] = :($(Symbol("c_$(i)")) = $ex3)
    end

    t = Expr(:tuple,  [Symbol("c_$(i)") for i = 1:N]...)
    pack = :(Series{T, N}($t))


    return Expr(
	:block,
	vars...,
	:(return $pack)
    )
end

function Base.:^(s::Series{T,N}, n::Int) where {T,N}

    sp = s
    np = n
    r = one(Series{T,N})
    while true
        if mod(np, 2) == 1
            r = r*sp
        end

        np = div(np, 2)
        if np == 0
            break
        end
        sp = sp*sp
    end
    return r
end

Base.promote_rule(s::Series{T,N}, x::Number) where {T,N} = Series{T,N}
Base.convert(::Type{Series{T,N}}, x::Number) where {T,N} = genseries(Series{T,N}, i -> i == 1 ? convert(T, x) : zero(T))


#Base.Float64(s::Series{Float64,N}) where N = s
#Base.AbstractFloat(s::Series{Float64,N}) where N = s
#Base.Int64(s::Series{Float64,N}) where N = s





