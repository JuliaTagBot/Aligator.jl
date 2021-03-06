
module Aligator

export aligator, extract_loop, closed_forms, invariants

using PyCall
using SymPy
using Singular
using AlgebraicDependencies

const AppliedUndef = PyCall.PyNULL()

include("utils.jl")
include("closedform.jl")
include("recurrence.jl")
include("loop.jl")
include("invariants.jl")
include("parse_julia.jl")
include("ideals.jl")
include("singular_imap.jl")


function aligator(str::String)
    _, total = @timed begin

        loop, time = @timed extract_loop(str)
        @debug "Recurrence extraction" time

        cforms, time = @timed closed_forms(loop)
        @debug "Recurrence solving" time
        
        invs, time = @timed invariants(cforms)
        @debug "Ideal computation" time
    end
    @debug "Total time needed" total
    
    return InvariantIdeal(invs)
end

function __init__()
    copy!(AppliedUndef, PyCall.pyimport_conda("sympy.core.function", "sympy").AppliedUndef)

    include(joinpath(@__DIR__,"..", "benchmark", "singlepath.jl"))
    include(joinpath(@__DIR__,"..", "benchmark", "multipath.jl"))

    singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
    multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]
end

struct InvariantIdeal
    ideal::sideal
end

function Base.show(io::IO, I::InvariantIdeal)
    println(io, "Invariant ideal with $(ngens(I.ideal))-element basis:")
    Base.print_array(io, gens(I.ideal))
end

end # module