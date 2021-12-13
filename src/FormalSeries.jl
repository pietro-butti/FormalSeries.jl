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

import Base.log

include("FormalSeriesTypes.jl")
export Series

include("FormalSeriesMath.jl")
export log, exp, sin, cos

end # module
