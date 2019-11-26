module Shapes

import Base: getindex, length, size
using Base: @pure, @propagate_inbounds, @_inline_meta

import Random
using Random: AbstractRNG

using Requires: @init, @require

import StaticArrays: Size, Length, similar_type, get
using StaticArrays: tuple_prod,
                    tuple_length,
                    tuple_minimum,
                    promote_tuple_eltype,
                    size_to_tuple,
                    SArray,
                    MArray,
                    StaticArray,
                    SOneTo


export AbstractShape,
       Shape,
       Size,
       Length,
       ScalarShape,
       VectorShape,
       MatrixShape,
       MultiShape,
       concrete_eltype,

       ShapedView,
       getindices,
       allocate


include("util.jl")
include("traits.jl")
include("ShapedView.jl")


getdims(shape::AbstractShape, dims) = getdims(Size(shape), dims)
getdims(s::Size, dims) = ((get(s)..., dims...))
getdims(::Size{()}, dims) = dims

Base.Array{T}(::UndefInitializer, shape::AbstractShape, dims::Dims) where {T} =
    Array{T}(undef, getdims(shape, dims))
Base.Array(::UndefInitializer, shape::AbstractShape, dims::Dims) =
    Array{concrete_eltype(shape)}(undef, shape, dims)

Base.Array{T}(::UndefInitializer, shape::AbstractShape, dims::Integer...) where {T} =
    Array{T}(undef, shape, dims)
Base.Array(::UndefInitializer, shape::AbstractShape, dims::Integer...) =
    Array(undef, shape, dims)

Base.Matrix{T}(::UndefInitializer, shape::AbstractShape, dim::Integer) where {T} =
    Matrix{T}(undef, getdims(shape, (dim,)))
Base.Matrix(::UndefInitializer, shape::AbstractShape, dim::Integer) =
    Matrix{concrete_eltype(shape)}(undef, shape, dim)

Base.Vector{T}(::UndefInitializer, shape::AbstractShape) where {T} =
    Vector{T}(undef, length(shape))
Base.Vector(::UndefInitializer, shape::AbstractShape) =
    Vector{concrete_eltype(shape)}(undef, shape)

Base.zeros(T, shape::AbstractShape, dims::Dims) = zeros(T, getdims(shape, dims))
Base.zeros(shape::AbstractShape, dims::Dims) = zeros(concrete_eltype(shape), shape, dims)

Base.zeros(T, shape::AbstractShape, dims::Integer...) = zeros(T, shape, dims)
Base.zeros(shape::AbstractShape, dims::Integer...) = zeros(shape, dims)

allocate(shape::AbstractShape, dims::Dims) = Array(undef, shape, dims)
allocate(shape::AbstractShape, dims::Integer...) = allocate(shape, dims)

allocate(T::DataType, dims::Dims) = Array{T}(undef, dims)
allocate(T::DataType, dims::Integer...) = allocate(T, dims)

allocate(T::DataType, shape::AbstractShape, dims::Dims) = allocate(T, size(shape)..., dims...)
allocate(T::DataType, shape::AbstractShape, dims::Integer...) = allocate(T, shape, dims)


function Random.rand(rng::AbstractRNG, shape::AbstractShape, dims::Dims)
    _rand(rng, concrete_eltype(shape), getdims(shape, dims))
end
Random.rand(rng::AbstractRNG, shape::AbstractShape, dims::Integer...) = rand(rng, shape, dims)

Random.rand(shape::AbstractShape, dims::Dims) = _rand(concrete_eltype(shape), getdims(shape, dims))
Random.rand(shape::AbstractShape, dims::Integer...) = rand(shape, dims)

_rand(rng, T, ::Dims{0}) = rand(rng, T)
_rand(rng, T, dims::Dims) = rand(rng, T, dims)
_rand(T, ::Dims{0}) = rand(T)
_rand(T, dims::Dims) = rand(T, dims)


# StaticArrays support
similar_type(::Type{SH}) where {SH<:AbstractShape} =
    SArray{tuple_to_size(get(Size(SH))),concrete_eltype(SH),ndims(SH),length(SH)}
similar_type(::SH) where {SH<:AbstractShape} = similar_type(SH)

similar_type(::Type{SA}, ::Type{SH}) where {SA<:StaticArray,SH<:AbstractShape} =
    similar_type(SA, concrete_eltype(SH), Size(SH))
similar_type(::SA, ::Type{SH}) where {SA<:StaticArray,SH<:AbstractShape} =
    similar_type(SA, concrete_eltype(SH), Size(SH))
similar_type(::Type{SA}, ::SH) where {SA<:StaticArray,SH<:AbstractShape} =
    similar_type(SA, concrete_eltype(SH), Size(SH))
similar_type(::SA, ::SH) where {SA<:StaticArray,SH<:AbstractShape} =
    similar_type(SA, concrete_eltype(SH), Size(SH))


@init @require ElasticArrays="fdbdab4c-e67f-52f5-8c3f-e7b388dad3d4" begin
    import .ElasticArrays
    ElasticArrays.ElasticArray(::UndefInitializer, shape::AbstractShape, dims::Dims) = ElasticArray{eltype(shape)}(undef, getdims(shape, dims)...)
    ElasticArrays.ElasticArray(::UndefInitializer, shape::AbstractShape, dims::Integer...) = ElasticArray(undef, shape, dims)
end


end # module
