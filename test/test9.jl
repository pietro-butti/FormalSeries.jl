using Test, FormalSeries

A = randn(3,4,6)
s = DSeries(A)

@testset "DSeries isbits" begin
    @test isbits(s)
end
@testset "Getting elements of DSeries" begin
    for i in 1:length(CartesianIndices(A))
        @test isapprox(A[CartesianIndex(i)], s[i])
    end
    for I in CartesianIndices(A)
        @test isapprox(A[I], s[I])
    end
end

