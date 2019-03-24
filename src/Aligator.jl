module Aligator

export aligator

using MacroTools
using SymEngine
using Recurrences
using AlgebraicDependencies
using Singular

include("looptransform.jl")
include("invariants.jl")
include("singular.jl")

aligator(s::String) = aligator(Meta.parse(s))

function aligator(x::Expr)
    _, total = @timed begin
        branches, etime = @timed extract_loops(x)
        vars = Base.unique(Iterators.flatten(map(Recurrences.free_symbols, branches)))
        @debug "Extracting branches" branches vars

        _, stime = @timed begin
            cforms = Vector{ClosedForm}[]
            for b in branches
                lrs = lrs_sequential(Vector{Expr}(b.args), :n)
                push!(cforms, Recurrences.solve(lrs))
            end
        end
        @debug "Closed forms" cforms

        invs, itime = @timed invariants(cforms, vars)
        @debug "Invariant ideal" invs
    end
    @info "Time needed" total etime stime itime

    return map(Meta.parse ∘ string, invs)
end

function __init__()
    include(joinpath(@__DIR__, "..", "benchmark", "singlepath.jl"))
    include(joinpath(@__DIR__, "..", "benchmark", "multipath.jl"))

    singlepath = [:cohencu, :freire1, :freire2, :(petter(1)), :(petter(2)), :(petter(3)), :(petter(4))]
    multipath = [:divbin, :euclidex, :fermat, :knuth, :lcm, :mannadiv, :wensley]
end

end # module