### AD tests for the ChainRulesCore extension.
### Goes in: test/testAD.jl  (and add `include("testAD.jl")` to runtests.jl)
###
### Loading ChainRulesCore here is what triggers the extension to load.

using Test, Random
using FormalSeries
using ChainRulesCore
using ChainRulesTestUtils
using FiniteDifferences
using Zygote

# --- Teach the testing stack about Series -----------------------------------

# vectorise a Series for FiniteDifferences (handles complex T automatically)
function FiniteDifferences.to_vec(s::Series{T,N}) where {T,N}
    v, back = FiniteDifferences.to_vec(collect(s.c))
    from_vec(x) = Series{T,N}(Tuple(back(x)))
    return v, from_vec
end

function ChainRulesTestUtils.rand_tangent(rng::AbstractRNG, s::Series{T,N}) where {T,N}
    return Series{T,N}(ntuple(_ -> randn(rng, T), N))
end

Base.isapprox(a::Series, b::Series; kw...) = all(isapprox(a.c[i], b.c[i]; kw...) for i in eachindex(a.c))

# tell ChainRulesTestUtils how to compare two Series (avoids collect(::Series))
function ChainRulesTestUtils.test_approx(actual::Series, expected::Series, msg=""; kwargs...)
    for i in eachindex(actual.c)
        ChainRulesTestUtils.test_approx(actual.c[i], expected.c[i], "$msg coeff[$i]"; kwargs...)
    end
end

# --- Per-primitive rrule checks ---------------------------------------------

@testset "rrule primitives (Series)" begin
    N  = 5
    # strictly positive constant term so log/sqrt are in-domain
    a  = Series{Float64,N}((1.7, 0.4, -0.3, 0.2, -0.1))
    b  = Series{Float64,N}((1.2, -0.5, 0.6, -0.2, 0.15))

    test_rrule(*, a, b)
    test_rrule(+, a, b)
    test_rrule(-, a, b)
    test_rrule(/, a, b)
    test_rrule(^, a, 3)

    test_rrule(*, 2.5, a)
    test_rrule(*, a, 2.5)
    test_rrule(/, a, 2.5)
    test_rrule(+, a, 2.5)

    test_rrule(log, a)
    test_rrule(exp, a)
    test_rrule(sin, a)
    test_rrule(cos, a)
    test_rrule(sqrt, a)
    # test_rrule(tanh, a)
end

@testset "bridge ops" begin
    a = Series{Float64,5}((1.7, 0.4, -0.3, 0.2, -0.1))
    test_rrule(+, 2.5, a)                                  # Number + Series (was untested)
    test_rrule(getindex, a, 3)
    test_rrule(Series{Float64,5}, (1.7, 0.4, -0.3, 0.2, -0.1))  # constructor
end

@testset "per-term end-to-end vs FD" begin
    N = 5
    v0  = [1.5, 0.3, -0.2, 0.1, 0.05]
    fdm = central_fdm(5, 1)
    mk(v) = Series{Float64,N}(Tuple(v))

    terms = (
        "log"  => (v -> (s = mk(v); sum(log(s).c))),
        "tanh" => (v -> (s = mk(v); sum(tanh(s*s).c))),
        "div"  => (v -> (s = mk(v); sum((s/(1.0+s)).c))),
        "full" => (v -> (s = mk(v); sum((log(s) + tanh(s*s) - s/(1.0+s)).c))),
    )
    for (name, f) in terms
        gz = Zygote.gradient(f, v0)[1]
        gf = FiniteDifferences.grad(fdm, f, v0)[1]
        ok = isapprox(gz, gf; rtol=1e-6, atol=1e-8)
        ok || @info "MISMATCH: $name" gz gf
        @testset "$name" begin
            @test ok
        end
    end
end

# --- End-to-end check through Zygote ----------------------------------------
# This is the strongest test: it exercises the bridge (constructor), the field
# ops, and the transcendentals together, and compares against finite differences.

@testset "Zygote end-to-end vs finite differences" begin
    N = 5
    function loss(v::Vector{Float64})
        s = Series{Float64,N}(Tuple(v))
        t = log(s) + tanh(s * s) - s / (1.0 + s)
        return sum(t.c)            # a real scalar
    end

    v0 = [1.5, 0.3, -0.2, 0.1, 0.05]          # v0[1] > 0  ⇒ log in-domain
    g_zyg = Zygote.gradient(loss, v0)[1]
    g_fd  = FiniteDifferences.grad(central_fdm(5, 1), loss, v0)[1]

    @test isapprox(g_zyg, g_fd; rtol=1e-6, atol=1e-8)
end