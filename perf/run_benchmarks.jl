using Random, BenchmarkTools, UnsafeArrays
push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using Shapes

include("util.jl")

# Define a parent BenchmarkGroup to contain our suite
suite = BenchmarkGroup()

suite["shapedview"] = BenchmarkGroup()
for N in (1, 10, 10^2, 10^4)
    group = suite["shapedview"][N] = BenchmarkGroup()
    bench, base = shapedview(N)
    group["bench"] = bench
    group["base"] = base
end

tune!(suite)
results = run(suite)
