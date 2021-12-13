###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    FormalSeriesMath.jl
### created: Mon Oct 11 02:13:49 2021
###                               

import Base.exp, Base.log, Base.sin, Base.cos

function log(s::Series{T,N}) where {T,N}

    tmp = Series{T,N}(ntuple(i -> i == 1 ? zero(T) : -s.c[i]/s.c[1], N))
    ls  = Series{T,N}(ntuple(i -> zero(T), N))
    x   = tmp
    for i in 2:N
        ls = ls - x/(i-1)
        x  = x*tmp                      
    end
    
    return ls + log(s.c[1])
end

function exp(s::Series{T,N}) where {T,N}

    tmp = Series{T,N}(ntuple(i -> i == 1 ? zero(T) : s.c[i],  N))
    es  = Series{T,N}(ntuple(i -> i == 1 ? one(T)  : zero(T), N))
    x   = tmp
    f   = one(T)
    for i in 2:N
        es = es + x/f

        x = x*tmp
        f = f*i
    end

    return exp(s.c[1])*es
end

function cos(s::Series{T,N}) where {T,N}

    tmp = Series{T,N}(ntuple(i -> i == 1 ? zero(T) : s.c[i],  N))
    esc = Series{T,N}(ntuple(i -> i == 1 ? one(T)  : zero(T), N))
    ess = Series{T,N}(ntuple(i -> zero(T), N))
    x   = tmp
    f   = one(T)
    for i in 2:2:N
        ess = ess + x/f
        x = -x*tmp
        f = f*i

        if (i == N)
            break
        end
        
        esc = esc + x/f
        x = x*tmp
        f = f*(i+1)
    end

    return cos(s.c[1])*esc - sin(s.c[1])*ess
end

function sin(s::Series{T,N}) where {T,N}

    tmp = Series{T,N}(ntuple(i -> i == 1 ? zero(T) : s.c[i],  N))
    esc = Series{T,N}(ntuple(i -> i == 1 ? one(T)  : zero(T), N))
    ess = Series{T,N}(ntuple(i -> zero(T), N))
    x   = tmp
    f   = one(T)
    for i in 2:2:N
        ess = ess + x/f
        x = -x*tmp
        f = f*i

        if (i == N)
            break
        end
        
        esc = esc + x/f
        x = x*tmp
        f = f*(i+1)
    end

    return sin(s.c[1])*esc + cos(s.c[1])*ess
end
