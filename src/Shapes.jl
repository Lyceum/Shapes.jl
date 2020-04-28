module Shapes

using Adapt: Adapt

using Base: OneTo, @pure, @propagate_inbounds, @_inline_meta
using DocStringExtensions
#using Random: Random, AbstractRNG
using Requires: @init, @require
using UnsafeArrays: UnsafeArrays

using StaticArrays: StaticArrays, Size, Length, StaticArray, SArray, MArray, SizedArray
using StaticArrays: similar_type
using StaticArrays: tuple_length, tuple_minimum, size_tuple # TODO should I rely on this?


export checkaxes, checksize
include("util.jl")

export AbstractShape, allocate
include("abstractshape.jl")

export AbstractStaticShape, SShape, SScalarShape, SVectorShape, SMatrixShape
include("staticshape.jl")

#include("composite.jl")

#include("ShapedView.jl")


# TODO
#@init @require ElasticArrays="fdbdab4c-e67f-52f5-8c3f-e7b388dad3d4" begin
#    import .ElasticArrays
#    ElasticArrays.ElasticArray(::UndefInitializer, shape::AbstractShape, dims::Dims) = ElasticArrays.ElasticArray{eltype(shape)}(undef, catdims(shape, dims)...)
#    ElasticArrays.ElasticArray(::UndefInitializer, shape::AbstractShape, dims::Integer...) = ElasticArrays.ElasticArray(undef, shape, dims)
#end

end # module
