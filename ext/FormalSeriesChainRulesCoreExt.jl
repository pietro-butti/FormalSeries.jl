### ChainRulesCore extension for FormalSeries.jl
### Goes in: ext/FormalSeriesChainRulesCoreExt.jl
### Scope: the flat `Series{T,N}` type only (DSeries left for later).
###
### Design: a Series is a vector space, so its differential is a Series
### ("natural" tangent). Every rule routes its VJP through `_mul_adjoint`,
### the adjoint of truncated multiplication.

module FormalSeriesChainRulesCoreExt

using FormalSeries
using ChainRulesCore
import LinearAlgebra

# `genseries` is internal/unexported; build via the public constructor instead.
@inline _series(::Type{Series{T,N}}, f) where {T,N} = Series{T,N}(ntuple(f, Val(N)))

# ---------------------------------------------------------------------------
# The one kernel: adjoint of "truncated multiply by g".
# If y = g*x  (c[i] = Σ_{k=1}^i g[k] x[i-k+1]), then  x̄[k] = Σ_{i=k}^N ȳ[i]·conj(g[i-k+1]).
# `conj` is identity for real T; it follows the ChainRules convention for complex T.
# ---------------------------------------------------------------------------
@inline function _mul_adjoint(g::Series{T,N}, w::Series{T,N}) where {T,N}
    _series(Series{T,N}, k -> begin
        acc = zero(T)
        @inbounds for i in k:N
            acc += w.c[i] * conj(g.c[i-k+1])
        end
        acc
    end)
end

# ---------------------------------------------------------------------------
# ProjectTo: the natural cotangent of a Series is a Series; enforce eltype and
# normalize any structural tangent that leaks in from a rule we didn't write.
# ---------------------------------------------------------------------------
# Encode eltype + length in the ProjectTo *type*: a concrete element-projector and a
# Val length. Storing the eltype as a plain DataType field is what made the rule
# return Series{_A,N} (abstract) and broke check_inferred.
ChainRulesCore.ProjectTo(s::Series{T,N}) where {T,N} =
    ChainRulesCore.ProjectTo{Series}(; element = ProjectTo(zero(T)), len = Val(N))

@inline _project_series(p, coeffs) =
    Series(ntuple(i -> p.element(coeffs[i]), p.len))

(p::ChainRulesCore.ProjectTo{Series})(dx::Series)            = _project_series(p, dx.c)
# Tangent{<:Series} is more specific than CRC's generic ProjectTo{T}(::Tangent{<:T}),
# which resolves the ambiguity Zygote hit.
(p::ChainRulesCore.ProjectTo{Series})(dx::Tangent{<:Series}) = _project_series(p, dx.c)
(p::ChainRulesCore.ProjectTo{Series})(dx::NamedTuple)        = _project_series(p, dx.c)

# ---------------------------------------------------------------------------
# Bilinear / field operations
# ---------------------------------------------------------------------------
function ChainRulesCore.rrule(::typeof(*), a::Series{T,N}, b::Series{T,N}) where {T,N}
    y = a * b
    pa, pb = ProjectTo(a), ProjectTo(b)
    function times_pb(ȳ)
        w = ProjectTo(y)(unthunk(ȳ))
        return (NoTangent(), pa(_mul_adjoint(b, w)), pb(_mul_adjoint(a, w)))
    end
    return y, times_pb
end

# q = b/a.  r = 1/a.  b̄ = adj(·r); ā = -adj(·(q*r)).
function ChainRulesCore.rrule(::typeof(/), b::Series{T,N}, a::Series{T,N}) where {T,N}
    q = b / a
    r = one(T) / a
    pa, pb = ProjectTo(a), ProjectTo(b)
    function div_pb(q̄)
        w = ProjectTo(q)(unthunk(q̄))
        return (NoTangent(), pb(_mul_adjoint(r, w)), pa(-_mul_adjoint(q * r, w)))
    end
    return q, div_pb
end

# integer power: dy = n·s^(n-1)·ds
function ChainRulesCore.rrule(::typeof(^), s::Series{T,N}, n::Int) where {T,N}
    y = s^n
    ps = ProjectTo(s)
    function pow_pb(ȳ)
        w = ProjectTo(y)(unthunk(ȳ))
        g = n == 0 ? zero(s) : (T(n) * s^(n - 1))
        return (NoTangent(), ps(_mul_adjoint(g, w)), NoTangent())
    end
    return y, pow_pb
end

# ---------------------------------------------------------------------------
# Linear operations (+, -, unary -)
# ---------------------------------------------------------------------------
function ChainRulesCore.rrule(::typeof(+), a::Series{T,N}, b::Series{T,N}) where {T,N}
    y = a + b
    pa, pb = ProjectTo(a), ProjectTo(b)
    add_pb(ȳ) = (w = ProjectTo(y)(unthunk(ȳ)); (NoTangent(), pa(w), pb(w)))
    return y, add_pb
end

function ChainRulesCore.rrule(::typeof(-), a::Series{T,N}, b::Series{T,N}) where {T,N}
    y = a - b
    pa, pb = ProjectTo(a), ProjectTo(b)
    sub_pb(ȳ) = (w = ProjectTo(y)(unthunk(ȳ)); (NoTangent(), pa(w), pb(-w)))
    return y, sub_pb
end

function ChainRulesCore.rrule(::typeof(-), a::Series{T,N}) where {T,N}
    y = -a
    pa = ProjectTo(a)
    neg_pb(ȳ) = (NoTangent(), pa(-ProjectTo(y)(unthunk(ȳ))))
    return y, neg_pb
end

# ---------------------------------------------------------------------------
# Scalar / Series mixed operations
# ---------------------------------------------------------------------------
function ChainRulesCore.rrule(::typeof(*), λ::Number, s::Series{T,N}) where {T,N}
    y = λ * s
    pλ, ps = ProjectTo(λ), ProjectTo(s)
    function smul_pb(ȳ)
        w  = ProjectTo(y)(unthunk(ȳ))
        λ̄ = sum(i -> w.c[i] * conj(s.c[i]), 1:N)
        s̄ = _series(Series{T,N}, i -> conj(λ) * w.c[i])
        return (NoTangent(), pλ(λ̄), ps(s̄))
    end
    return y, smul_pb
end
function ChainRulesCore.rrule(::typeof(*), s::Series{T,N}, λ::Number) where {T,N}
    y = s * λ
    ps, pλ = ProjectTo(s), ProjectTo(λ)
    function smul_pb2(ȳ)
        w  = ProjectTo(y)(unthunk(ȳ))
        s̄ = _series(Series{T,N}, i -> w.c[i] * conj(λ))
        λ̄ = sum(i -> conj(s.c[i]) * w.c[i], 1:N)
        return (NoTangent(), ps(s̄), pλ(λ̄))
    end
    return y, smul_pb2
end

function ChainRulesCore.rrule(::typeof(/), s::Series{T,N}, λ::Number) where {T,N}
    y = s / λ
    ps, pλ = ProjectTo(s), ProjectTo(λ)
    function sdiv_pb(ȳ)
        w  = ProjectTo(y)(unthunk(ȳ))
        s̄ = _series(Series{T,N}, i -> w.c[i] / conj(λ))
        λ̄ = -sum(i -> conj(y.c[i]) * w.c[i], 1:N) / conj(λ)
        return (NoTangent(), ps(s̄), pλ(λ̄))
    end
    return y, sdiv_pb
end

# λ/s = λ·inv(s);  dy = -(y·r) ds,  r = 1/s
function ChainRulesCore.rrule(::typeof(/), λ::Number, s::Series{T,N}) where {T,N}
    y = λ / s
    r = one(T) / s
    pλ, ps = ProjectTo(λ), ProjectTo(s)
    function ndiv_pb(ȳ)
        w  = ProjectTo(y)(unthunk(ȳ))
        λ̄ = sum(i -> w.c[i] * conj(r.c[i]), 1:N)
        s̄ = -_mul_adjoint(y * r, w)
        return (NoTangent(), pλ(λ̄), ps(s̄))
    end
    return y, ndiv_pb
end

# Series ± Number  (the scalar only touches the constant term)
function ChainRulesCore.rrule(::typeof(+), s::Series{T,N}, λ::Number) where {T,N}
    y = s + λ
    ps, pλ = ProjectTo(s), ProjectTo(λ)
    addn_pb(ȳ) = (w = ProjectTo(y)(unthunk(ȳ)); (NoTangent(), ps(w), pλ(w.c[1])))
    return y, addn_pb
end
function ChainRulesCore.rrule(::typeof(+), λ::Number, s::Series{T,N}) where {T,N}
    y = λ + s
    pλ, ps = ProjectTo(λ), ProjectTo(s)
    naddn_pb(ȳ) = (w = ProjectTo(y)(unthunk(ȳ)); (NoTangent(), pλ(w.c[1]), ps(w)))
    return y, naddn_pb
end
function ChainRulesCore.rrule(::typeof(-), s::Series{T,N}, λ::Number) where {T,N}
    y = s - λ
    ps, pλ = ProjectTo(s), ProjectTo(λ)
    subn_pb(ȳ) = (w = ProjectTo(y)(unthunk(ȳ)); (NoTangent(), ps(w), pλ(-w.c[1])))
    return y, subn_pb
end
function ChainRulesCore.rrule(::typeof(-), λ::Number, s::Series{T,N}) where {T,N}
    y = λ - s
    pλ, ps = ProjectTo(λ), ProjectTo(s)
    nsubn_pb(ȳ) = (w = ProjectTo(y)(unthunk(ȳ)); (NoTangent(), pλ(w.c[1]), ps(-w)))
    return y, nsubn_pb
end

# ---------------------------------------------------------------------------
# Transcendentals: y = f(s), s̄ = adj(·f'(s)) applied to ȳ.
# (Closed-form; we never trace the iterative bodies in FormalSeriesMath.jl.)
# Written on Series{T,N}; widen to AbstractSeries once DSeries has _mul_adjoint.
# ---------------------------------------------------------------------------
function ChainRulesCore.rrule(::typeof(Base.log), s::Series{T,N}) where {T,N}   # domain: s.c[1] > 0
    y = Base.log(s); g = one(T) / s; ps = ProjectTo(s)
    pb(ȳ) = (NoTangent(), ps(_mul_adjoint(g, ProjectTo(y)(unthunk(ȳ)))))
    return y, pb
end
function ChainRulesCore.rrule(::typeof(Base.exp), s::Series{T,N}) where {T,N}
    y = Base.exp(s); ps = ProjectTo(s)
    pb(ȳ) = (NoTangent(), ps(_mul_adjoint(y, ProjectTo(y)(unthunk(ȳ)))))   # f'(s) = y
    return y, pb
end
function ChainRulesCore.rrule(::typeof(Base.sin), s::Series{T,N}) where {T,N}
    y = Base.sin(s); g = Base.cos(s); ps = ProjectTo(s)
    pb(ȳ) = (NoTangent(), ps(_mul_adjoint(g, ProjectTo(y)(unthunk(ȳ)))))
    return y, pb
end
function ChainRulesCore.rrule(::typeof(Base.cos), s::Series{T,N}) where {T,N}
    y = Base.cos(s); g = -Base.sin(s); ps = ProjectTo(s)
    pb(ȳ) = (NoTangent(), ps(_mul_adjoint(g, ProjectTo(y)(unthunk(ȳ)))))
    return y, pb
end
function ChainRulesCore.rrule(::typeof(Base.sqrt), s::Series{T,N}) where {T,N}  # domain: s.c[1] ≠ 0
    y = Base.sqrt(s); g = one(T) / (2 * y); ps = ProjectTo(s)
    pb(ȳ) = (NoTangent(), ps(_mul_adjoint(g, ProjectTo(y)(unthunk(ȳ)))))
    return y, pb
end
# function ChainRulesCore.rrule(::typeof(Base.tanh), s::Series{T,N}) where {T,N}
#     y = Base.tanh(s); g = one(s) - y * y; ps = ProjectTo(s)
#     pb(ȳ) = (NoTangent(), ps(_mul_adjoint(g, ProjectTo(y)(unthunk(ȳ)))))
#     return y, pb
# end
# norm is the identity on a real Series (package "cheat"), so its rule is identity.
function ChainRulesCore.rrule(::typeof(LinearAlgebra.norm), s::Series{T,N}) where {T<:Real,N}
    y = LinearAlgebra.norm(s)
    ps = ProjectTo(s)
    pb(ȳ) = (NoTangent(), ps(ProjectTo(y)(unthunk(ȳ))))
    return y, pb
end

# ---------------------------------------------------------------------------
# Bridge: constructors / convert / getindex (where gradients cross reals <-> Series)
# ---------------------------------------------------------------------------
function ChainRulesCore.rrule(::Type{Series{T,N}}, c::NTuple{N,T}) where {T,N}
    y = Series{T,N}(c)
    function cons_pb(ȳ)
        cbar = ProjectTo(y)(unthunk(ȳ)).c            # NTuple{N,T}
        return (NoTangent(), Tangent{NTuple{N,T}}(cbar...))
    end
    return y, cons_pb
end

function ChainRulesCore.rrule(::Type{Series}, c::NTuple{N,T}) where {T,N}
    y = Series(c)
    function cons_pb(ȳ)
        cbar = ProjectTo(y)(unthunk(ȳ)).c
        return (NoTangent(), Tangent{NTuple{N,T}}(cbar...))
    end
    return y, cons_pb
end


function ChainRulesCore.rrule(::typeof(convert), ::Type{Series{T,N}}, x::Number) where {T,N}
    y = convert(Series{T,N}, x)
    px = ProjectTo(x)
    conv_pb(ȳ) = (NoTangent(), NoTangent(), px(ProjectTo(y)(unthunk(ȳ)).c[1]))
    return y, conv_pb
end

# Prefer s[i] over s.c[i] in flow code so this rule fires (s.c[i] hits getfield).
function ChainRulesCore.rrule(::typeof(getindex), s::Series{T,N}, i::Integer) where {T,N}
    y = s[i]
    ps = ProjectTo(s)
    function gi_pb(ȳ)
        c̄ = unthunk(ȳ)
        s̄ = _series(Series{T,N}, k -> k == i ? convert(T, c̄) : zero(T))
        return (NoTangent(), ps(s̄), NoTangent())
    end
    return y, gi_pb
end

end # module