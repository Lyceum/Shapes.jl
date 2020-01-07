using Random, BenchmarkTools, UnsafeArrays, Statistics
using BenchmarkTools: prettytime, prettypercent

push!(LOAD_PATH, joinpath(@__DIR__, ".."))
using Shapes

include("benchmarks.jl")

function bgroup!(suite_or_group, name, bench, std)
    g = suite_or_group[name] = BenchmarkGroup()
    g["bench"] = bench
    g["std"] = std
    g
end


# Define a parent BenchmarkGroup to contain our suite
suite = BenchmarkGroup()

suite["sv"] = BenchmarkGroup()
bgroup!(suite["sv"], "vs_assign", sv_vs_assign()...)
bgroup!(suite["sv"], "ms_assign", sv_ms_assign()...)
bgroup!(suite["sv"], "ms_nested_assign", sv_ms_nested_assign()...)

summarize_results(suite_or_group) = summarize_results(suite_or_group, "")
function summarize_results(suite_or_group, name)
    if haskey(suite_or_group, "bench")
        println()
        println("Benchmark $name")
        bench, std = median.(values(suite_or_group))
        if bench.allocs != 0
            @warn "Non-zero allocs in bench: $(bench.allocs)"
        end
        if std.allocs != 0
            @error "Non-zero allocs in std: $(std.allocs)"
        end
        bench_t = time(bench)
        std_t = time(std)
        ratio = (bench_t - std_t) / std_t

        str = "Bench: $(prettytime(bench_t))"
        str *= " Std: $(prettytime(std_t))"
        str *= " Percent slower: $(prettypercent(ratio))"
        println(str)
    else
        for (k, v) in suite_or_group
            summarize_results(v, k)
        end
    end
end

function run_benchmarks()
    tune!(suite)
    results = run(suite)
    summarize_results(results)
    results
end

run_benchmarks()