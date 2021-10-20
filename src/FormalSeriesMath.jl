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

import Base.exp, Base.log

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

    println("dentro: ", es)
    return exp(s.c[1])*es
end
