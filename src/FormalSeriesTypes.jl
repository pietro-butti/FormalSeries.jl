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

struct Series{T,N}
    c::NTuple{N,T}
end

import Base.:+, Base.:-, Base.:*, Base.:/, Base.:^

Base.:+(s1::Series{T,N})                  where {T,N} = s1
Base.:+(s1::Series{T,N}, s2::Series{T,N}) where {T,N} = Series{T,N}(ntuple(i -> s1.c[i] + s2.c[i], N))
Base.:+(s1::Series{T,N}, s2::Number)      where {T,N} = Series{T,N}(ntuple(i -> i == 1 ? s1.c[1] + s2 : s1.c[i], N))
Base.:+(s2::Number, s1::Series{T,N})      where {T,N} = Series{T,N}(ntuple(i -> i == 1 ? s1.c[1] + s2 : s1.c[i], N))

Base.:-(s1::Series{T,N})                  where {T,N} = Series{T,N}(ntuple(i -> -s1.c[i], N))
Base.:-(s1::Series{T,N}, s2::Series{T,N}) where {T,N} = Series{T,N}(ntuple(i -> s1.c[i] - s2.c[i], N))
Base.:-(s1::Series{T,N}, s2::Number)      where {T,N} = Series{T,N}(ntuple(i -> i == 1 ?  s1.c[1] - s2 :  s1.c[i], N))
Base.:-(s2::Number, s1::Series{T,N})      where {T,N} = Series{T,N}(ntuple(i -> i == 1 ? -s1.c[1] + s2 : -s1.c[i], N))



function Base.:*(s1::Series{T,N}, s2::Series{T,N}) where {T,N}

    @inline function mul(i)
        c = s1.c[1]*s2.c[i]
        @inbounds for k in 2:i
            c = c + s1.c[k]*s2.c[i-k+1]
        end
        return c
    end
    
    return Series(ntuple(mul, N))
end
Base.:*(s1::Series{T,N}, s2::Number)      where {T,N} = Series{T,N}(ntuple(i -> s1.c[i]*s2, N))
Base.:*(s2::Number, s1::Series{T,N})      where {T,N} = Series{T,N}(ntuple(i -> s2*s1.c[i], N))

function Base.:/(s1::Series{T,N}, s2::Series{T,N}) where {T,N}

    @inline function div(i)
        if i == 1
            return s1.c[1]/s2.c[1]
        else
            c = s1.c[i]
            @inbounds for k in 2:i
                c = c - s2.c[k]*div(i-k+1)
            end
            c = c/s2.c[1]
        end
        return c
    end    
    
    return Series(ntuple(div, N))
end
Base.:/(s1::Series{T,N}, s2::Number)      where {T,N} = Series{T,N}(ntuple(i -> s1.c[i]/s2, N))
function Base.:/(s2::Number, s1::Series{T,N})  where {T,N}
    @inline function div(i)
        if i == 1
            return s2/s1.c[1]
        else
            c = -s1.c[2]*div(i-1)
            @inbounds for k in 3:i
                c = c - s1.c[k]*div(i-k+1)
            end
            c = c/s1.c[1]
        end
        return c
    end    
    
    return Series(ntuple(div, N))
end

function Base.:^(s::Series{T,N}, n::Int) where {T,N}

    sp = s
    np = n
    r = Series(ntuple(i -> i == 1 ? one(T) : zero(T), N))
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

    
