"""
    $(TYPEDEF)

The supertype for `N`-dimensional shapes with elements of type `T`.
"""
abstract type AbstractShape{T,N} end


Base.eltype(s::AbstractShape) = eltype(typeof(s))
Base.eltype(::Type{<:AbstractShape{T}}) where {T} = @isdefined(T) ? T : Any

concrete_eltype(s::AbstractShape) = concrete_type(eltype(s))

Base.ndims(s::AbstractShape) = ndims(typeof(s))
Base.ndims(::Type{<:AbstractShape{T,N}}) where {T,N} = N

# At a minimum, s::AbstractShape should implement Base.size(s)
@inline Base.size(s::AbstractShape{T,N}, d::Integer) where {T,N} = d <= N ? size(s)[d] : 1

@inline Base.axes(s::AbstractShape) = map(OneTo, size(s))
@inline Base.axes(s::AbstractShape{T,N}, d::Integer) where {T,N} = d <= N ? axes(s)[d] : OneTo(1)

@inline Base.length(s::AbstractShape) = prod(size(s))

# TODO this wouldn't make sense for e.g. BoundedShape which isn't a singleton type
Base.:(==)(s1::AbstractShape, s2::AbstractShape) = axes(s1) == axes(s2)



function Base.Array{T,N}(::UndefInitializer, shape::AbstractShape, dims::TupleN{Integer}) where {T,N}
    Array{T,N}(undef, size(shape)..., dims...)
end
function Base.Array{T,N}(::UndefInitializer, shape::AbstractShape, dims::Integer...) where {T,N}
    Array{T,N}(undef, shape, dims)
end

function Base.Array{T}(::UndefInitializer, shape::AbstractShape, dims::TupleN{Integer}) where {T}
    Array{T}(undef, size(shape)..., dims...)
end
function Base.Array{T}(::UndefInitializer, shape::AbstractShape, dims::Integer...) where {T}
    Array{T}(undef, shape, dims)
end

function Base.Array(::UndefInitializer, shape::AbstractShape, dims::TupleN{Integer})
    Array{concrete_eltype(shape)}(undef, size(shape)..., dims...)
end
Base.Array(::UndefInitializer, shape::AbstractShape, dims::Integer...) = Array(undef, shape, dims)

# TODO
#function Base.Matrix{T}(::UndefInitializer, shape::AbstractVectorShape, dim::Integer)
#    Matrix{T}(undef, length(shape), dim)
#end
#    Matrix{T}(undef, catdims(shape, (dim,)))
#Base.Matrix(::UndefInitializer, shape::AbstractShape, dim::Integer) =
#    Matrix{concrete_eltype(shape)}(undef, shape, dim)

#Base.Vector{T}(::UndefInitializer, shape::AbstractShape) where {T} =
#    Vector{T}(undef, length(shape))
#Base.Vector(::UndefInitializer, shape::AbstractShape) =
#    Vector{concrete_eltype(shape)}(undef, shape)


Base.zeros(T::Type, shape::AbstractShape, dims::TupleN{Integer}) = zeros(T, size(shape)..., dims...)
Base.zeros(T::Type, shape::AbstractShape, dims::Integer...) = zeros(T, shape, dims)

Base.zeros(shape::AbstractShape, dims::TupleN{Integer}) = zeros(concrete_eltype(shape), shape, dims)
Base.zeros(shape::AbstractShape, dims::Integer...) = zeros(shape, dims)


# TODO
#function Random.rand(rng::AbstractRNG, shape::AbstractShape, dims::Dims)
#    _rand(rng, concrete_eltype(shape), catdims(shape, dims))
#end
#Random.rand(rng::AbstractRNG, shape::AbstractShape, dims::Integer...) = rand(rng, shape, dims)

#Random.rand(shape::AbstractShape, dims::Dims) = _rand(concrete_eltype(shape), catdims(shape, dims))
#Random.rand(shape::AbstractShape, dims::Integer...) = rand(shape, dims)

#_rand(rng, T, ::Dims{0}) = rand(rng, T)
#_rand(rng, T, dims::Dims) = rand(rng, T, dims)
#_rand(T, ::Dims{0}) = rand(T)
#_rand(T, dims::Dims) = rand(T, dims)


const ShapeOrDims = Union{AbstractShape, TupleN{Integer}, Integer}
allocate(T::Type, dims::ShapeOrDims...) = Array{T}(undef, mapfoldl(asdims, tuplejoin, dims))
allocate(dims::ShapeOrDims...) = allocate(foldl(maybe_promote_eltype, dims), dims...) # TODO test

asdims(shape::AbstractShape) = size(shape)
asdims(x::Integer) = x
asdims(x::TupleN{Integer}) = x
asdims(x) = argerror("Expected an Integer, tuple of Integers, or an AbstractShape. Got $(typeof(x))")
