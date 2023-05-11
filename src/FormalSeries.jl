###
### "THE BEER-WARE LICENSE":
### Alberto Ramos wrote this file. As long as you retain this 
### notice you can do whatever you want with this stuff. If we meet some 
### day, and you think this stuff is worth it, you can buy me a beer in 
### return. <alberto.ramos@cern.ch>
###
### file:    FormalSeries.jl
### created: Sun Sep 26 22:08:05 2021
###                               


module FormalSeries

using StaticArrays, PrecompileTools

import Base.log

include("FormalSeriesTypes.jl")
export AbstractSeries, Series, DSeries

include("FormalSeriesMath.jl")
export log, exp, sin, cos, sqrt, tanh

#
# Precompile Extensions
#
@compile_workload begin

    r = 2.3
    x = Series((1.0,2.0,))
    y = DSeries([1.2 3.4 
                 2.3 3.4])

    for op in (:+,:-,:*,:/)
        z = @eval $op($x,$x)
        z = @eval $op($r,$x)
        z = @eval $op($y,$y)
        z = @eval $op($y,$r)
    end

    for op in (:+,:-,:sin,:cos,:log,:exp,:tanh,:sqrt)
        z = @eval $op($x)
        z = @eval $op($y)
    end
end


end # module
