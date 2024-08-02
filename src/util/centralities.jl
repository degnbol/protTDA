"""
Taken from centrality_tools.jl in repo node-edge-hypergraph-centrality.
fgϕψs defined according to the max method (see Tudisco et al. 2021).
Modified to only return node centralities since edge centralities were 
too similar to the input persistences.
Modified to return zeros for trivial input.
"""
function centralities(B; maxiter::Int=100, tol::Float64=1e-6,
                      edge_weights::Vector{Float64}=ones(size(B,2)),
                      node_weights::Vector{Float64}=ones(size(B,1)))

    # f is omitted since it is identity function
    g = x->x .^ (1/ 5)
    ϕ = x->x .^    15
    ψ = x->x .^ (1/15)

    n,m = size(B)
    m > 0 || return zeros(n)

    x0 = fill(1/n, n)
    y0 = fill(1/m, m)

    W = spdiagm(edge_weights)
    N = spdiagm(node_weights)

    for _ in 1:maxiter
        x = normalize(sqrt.(x0 .* g(B  * W *   y0 )), 1)
        y = normalize(sqrt.(y0 .* ψ(B' * N * ϕ(x0))), 1)

        norm(x-x0,1) + norm(y-y0,1) < tol && return x

        x0 = x
        y0 = y
    end
    x0
end
