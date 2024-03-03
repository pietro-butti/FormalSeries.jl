
using Test, FormalSeries, QuadGK

function ana_num(I, theta)
    return phi -> (I * (1-cos(phi)) + theta*sin(phi)/(2pi)) * exp(-I * (1-cos(phi)) - theta*sin(phi)/(2pi))
end

function ana_den(I, theta)
    return phi -> exp(-I * (1-cos(phi)) - theta*sin(phi)/(2pi))
end

function integral_ana(I, theta)
    return quadgk(ana_num(I, theta), -pi, pi)[1] / quadgk(ana_den(I, theta), -pi, pi)[1]
end

@testset "Compatibility with QuadGK" begin

    theta = Series((0.0, 1.0, 0.0))
    res = integral_ana(5.0, theta)

    @test isapprox(res.c[2], 0.0, atol=10e-10)
    @test isapprox(res.c[3], -0.0025354004219348887)

end




