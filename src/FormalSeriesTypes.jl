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
abstract type AbstractSeries{T,O} end#<: Real end
order(s::AbstractSeries{T,O}) where {T,O} = O

struct Series{T,N} <: AbstractSeries{T,N}
    c::NTuple{N,T}
end
Series{T,N}(x::Series{T,N}) where {T,N} = x

# Non-allocating version of ntuple function
@generated function gentup(::Type{NTuple{N,T}}, f) where {T,N}
    vars = Vector{Expr}(undef, N)
    for i in 1:N
        vars[i] = Expr(:call, :(f), i)
    end
    t = Expr(:tuple,  [vars[i] for i = 1:N]...)
    
    return Expr(
	:block,
	:(return $t)
    )
end
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

# Getting index
import Base.getindex, Base.eltype
Base.getindex(s::Series{T,N}, i::Integer) where {T,N} = s.c[i]
Base.eltype(s::Series{T,N}) where {T,N} = T

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
	    [:( a.c[$(i-k+1)] * $(Symbol("c_$(k)")) ) for k in 1:i-1]...
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
	    [:( a.c[$(i-k+1)] * $(Symbol("c_$(k)")) ) for k in 1:i-1]...
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

function Base.:^(s::AbstractSeries, n::Int)

    sp = s
    np = n
    r = one(s)
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

##
# D dimensional implementation
##
Base.@pure tuple_max(T::Type{<:Tuple}) = length(T.parameters) == 0 ? 0 : sum(tuple(T.parameters...))
Base.@pure tuple_prd(T::Type{<:Tuple}) = length(T.parameters) == 0 ? 1 : *(T.parameters...)
Base.@pure tuple_prd(T::Tuple)         = prod(T)
Base.@pure tuple_l(T::Type{<:Tuple})   = length(T.parameters)
struct DSeries{S<:Tuple,T,N,D,O} <: AbstractSeries{T,O}
    c::SArray{S,T,D,N}
    function DSeries(A::Array{T,N}) where {T,N}
        NL = tuple_prd(size(A))
        return new{Tuple{size(A)...},T,NL,N,sum(size(A))}(gentup(NTuple{NL,T}, i -> A[CartesianIndex(i)]))
    end
    
    DSeries{S,T,N,D,O}(a::NTuple{N,T}) where {S,T,N,D,O} = new{S,T,N,D,O}(a)
end
@inline DSeries{S,T,D}(a::NTuple{N,T}) where {S,T,N,D} = DSeries{S,T,N,D,tuple_max(S)}(a)
@inline DSeries{S}(c::NTuple{N,T}) where {S,T,N} = DSeries{S,T,N,tuple_l(S),tuple_max(S)}(c)

Base.getindex(s::DSeries{S,T,N,D,O}, i::Integer) where {S,T,N,D,O} = s.c.data[i]
Base.getindex(s::DSeries{S,T,N,D,O}, i::Integer...) where {S,T,N,D,O} = s.c[i...]
Base.getindex(s::DSeries{S,T,N,D,O}, I) where {S,T,N,D,O} = s.c[I]
Base.eltype(s::DSeries{S,T,N,D,O}) where {S,T,N,D,O} = T

@generated function genseries(::Type{DSeries{S,T,N,D,O}}, f) where {S,T,N,D,O}
    vars = Vector{Expr}(undef, N)
    for i in 1:N
        vars[i] = Expr(:call, :(f), i)
    end
    t = Expr(:tuple,  [vars[i] for i = 1:N]...)
    pack = :(DSeries{S}($t))
    
    return Expr(
	:block,
	:(return $pack)
    )
end

Base.one(::Type{DSeries{S,T,N,D,O}})  where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> i == 1 ? one(T)  : zero(T))
Base.one(s::DSeries{S,T,N,D,O})       where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> i == 1 ? one(T)  : zero(T))
Base.zero(::Type{DSeries{S,T,N,D,O}}) where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> zero(T))
Base.zero(s::DSeries{S,T,N,D,O})      where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> zero(T))
Base.conj(x::DSeries{S,T,N,D,O})      where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> conj(x.c[i]))
Base.imag(x::DSeries{S,T,N,D,O})      where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> imag(x.c[i]))
Base.real(x::DSeries{S,T,N,D,O})      where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> real(x.c[i]))


## Evaluation of series
function (s1::DSeries{S,T,N,D,O})(x) where {S,T,N,D,O}

    ss = zero(T)
    for I in s1.cindx
        ss = ss + s1[I] * prod(x .^ (Tuple(I).-1))
    end

    return ss
end


Base.:+(s1::DSeries{S,T,N,D,O})                        where {S,T,N,D,O} = s1
Base.:+(s1::DSeries{S,T,N,D,O},s2::DSeries{S,T,N,D,O}) where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> s1[i]+s2[i])
Base.:+(s1::DSeries{S,T,N,D,O},s2::Number)             where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> i == 1 ? s1[i]+s2 : s1[i])
Base.:+(s2::Number,s1::DSeries{S,T,N,D,O})             where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> i == 1 ? s1[i]+s2 : s1[i])

Base.:-(s1::DSeries{S,T,N,D,O})                        where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> -s1[i])
Base.:-(s1::DSeries{S,T,N,D,O},s2::DSeries{S,T,N,D,O}) where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> s1[i]-s2[i])
Base.:-(s1::DSeries{S,T,N,D,O},s2::Number)             where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> i == 1 ? s1[i]-s2 : s1[i])
Base.:-(s2::Number,s1::DSeries{S,T,N,D,O})             where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> i == 1 ? s2-s1[i] : -s1[i])

@generated function Base.:*(s1::DSeries{S,T,N,D,O}, s2::DSeries{S,T,N,D,O}) where {S,T,N,D,O}
    vars = Vector{Expr}(undef, N)
    R = CartesianIndices(tuple(S.parameters...))
    I1 = first(R)
    L = LinearIndices(tuple(S.parameters...))
    for I in R
	ex = Expr(
	    :call,
	    :+,
	    [:( s1[$K] * s2[$(I-K+I1)] ) for K in I1:I]...
	        )
        
        k = L[I]
        vars[k] = :($(Symbol("c_$(k)")) = $ex)
    end
    t = Expr(:tuple,  [Symbol("c_$(i)") for i = 1:N]...)
    pack = :(DSeries{S,T,N,D,O}($t))

    return Expr(
	:block,
	vars...,
	:(return $pack)
    )

end

Base.:*(s1::DSeries{S,T,N,D,O}, s2::Number)      where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> s1.c[i]*s2)
Base.:*(s2::Number, s1::DSeries{S,T,N,D,O})      where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O}, i -> s2*s1.c[i])


@generated function Base.:/(s1::DSeries{S,T,N,D,O}, s2::DSeries{S,T,N,D,O}) where {S,T,N,D,O}
    vars = Vector{Expr}(undef, N)
    R = CartesianIndices(tuple(S.parameters...))
    I1 = first(R)
    L = LinearIndices(tuple(S.parameters...))
    for I in R
        k = L[I]
        if I == I1
            expr = Expr(:call,:(/),:(s1[$I1]),:(s2[$I1]))
            vars[k] = :($(Symbol("c_1")) = $expr)
        else
            EE = Vector{Expr}()
            for K in I1:I
                if K != I
                    j = L[K]
                    push!(EE, :( s2[$(I-K+I1)] * $(Symbol("c_$(j)")) ))
                end
            end
            ex = Expr(
                :call,
                :+, EE...)
            
            ex2 = Expr(:call, :-, :(s1[$I]), ex)
            ex3 = Expr(:call, :/, ex2, :(s2[$I1]))
            
            vars[k] = :($(Symbol("c_$(k)")) = $ex3)
        end
    end
    
    t = Expr(:tuple,  [Symbol("c_$(i)") for i = 1:N]...)
    pack = :(DSeries{S,T,N,D,O}($t))
    
    return Expr(
        :block,
        vars...,
        :(return $pack)
    )
    
end

@generated function Base.:/(s1::Number, s2::DSeries{S,T,N,D,O}) where {S,T,N,D,O}
    vars = Vector{Expr}(undef, N)
    R = CartesianIndices(tuple(S.parameters...))
    I1 = first(R)
    L = LinearIndices(tuple(S.parameters...))
    for I in R
        k = L[I]
        if I == I1
            expr = Expr(:call,:(/),:(s1),:(s2[$I1]))
            vars[k] = :($(Symbol("c_1")) = $expr)
        else
            EE = Vector{Expr}()
            for K in I1:I
                if K != I
                    j = L[K]
                    push!(EE, :( s2[$(I-K+I1)] * $(Symbol("c_$(j)")) ))
                end
            end
            ex = Expr(
                :call,
                :+, EE...)
            
            ex2 = Expr(:call, :-, ex)
            ex3 = Expr(:call, :/, ex2, :(s2[$I1]))
            
            vars[k] = :($(Symbol("c_$(k)")) = $ex3)
        end
    end
    
    t = Expr(:tuple,  [Symbol("c_$(i)") for i = 1:N]...)
    pack = :(DSeries{S,T,N,D,O}($t))
    
    return Expr(
        :block,
        vars...,
        :(return $pack)
    )
    
end

Base.:/(s1::DSeries{S,T,N,D,O}, s2::Number)      where {S,T,N,D,O} = genseries(DSeries{S,T,N,D,O},i -> s1.c[i]/s2)

