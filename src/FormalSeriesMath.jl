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

import Base.exp, Base.log, Base.sin, Base.cos, Base.sqrt, Base.tanh

function log(s::AbstractSeries{T,O}) where {T,O}

    tmp = genseries(typeof(s), i -> i == 1 ? zero(T) : -s.c[i]/s.c[1])
    ls  = zero(s)
    x   = tmp
    for i in 2:O
        ls = ls - x/(i-1)
        x  = x*tmp                      
    end
    
    return ls + log(s.c[1])
end

function exp(s::AbstractSeries{T,O}) where {T,O}

    tmp = genseries(typeof(s),i -> i == 1 ? zero(T) : s.c[i])
    es  = one(s)
    x   = tmp
    f   = one(T)
    for i in 2:O
        es = es + x/f

        x = x*tmp
        f = f*i
    end

    return exp(s.c[1])*es
end

function cos(s::AbstractSeries{T,O}) where {T,O}

    tmp = genseries(typeof(s), i -> i == 1 ? zero(T) : s.c[i])
    esc = one(s)
    ess = zero(s)
    x   = tmp
    f   = one(T)
    for i in 2:2:O
        ess = ess + x/f
        x = -x*tmp
        f = f*i

        if (i == O)
            break
        end
        
        esc = esc + x/f
        x = x*tmp
        f = f*(i+1)
    end

    return cos(s.c[1])*esc - sin(s.c[1])*ess
end

function sin(s::AbstractSeries{T,O}) where {T,O}

    tmp = genseries(typeof(s), i -> i == 1 ? zero(T) : s.c[i])
    esc = one(s)
    ess = zero(s)
    x   = tmp
    f   = one(T)
    for i in 2:2:O
        ess = ess + x/f
        x = -x*tmp
        f = f*i

        if (i == O)
            break
        end
        
        esc = esc + x/f
        x = x*tmp
        f = f*(i+1)
    end

    return sin(s.c[1])*esc + cos(s.c[1])*ess
end

function sqrt(s::AbstractSeries{T,O}) where {T,O}

    tmp = genseries(typeof(s), i -> i == 1 ? zero(T) : s.c[i]/s.c[1])
    ls  = one(s)
    x   = tmp
    a   = 1.0
    for n in 0:O-2
        a = a*(-1)*(2*n+2)*(2*n-1)/(4*(n+1)^2)
        ls = ls + a*x
        x  = x*tmp                      
    end
    
    return sqrt(s.c[1])*ls
end

function tanh(s::AbstractSeries{T,O}) where {T,O}

    nmax = div(O,2)
    d = 2*nmax+1
    x2 = s*s
    x  = x2/d
    for k in nmax:-1:2
        d = d-2
        x = x2/(d+x)
    end

    return s/(one(T)+x)
end


import LinearAlgebra.norm

LinearAlgebra.norm(s::FormalSeries.Series{T,N}) where {T <: Real,N} = s
LinearAlgebra.norm(s::FormalSeries.Series{T,N}) where {T <: Complex,N} = sqrt(real(s)^2 + imag(s)^2)
