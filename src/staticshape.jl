"""
    $(TYPEDEF)

The supertype for `N`-dimensional statically-sized shapes with elements of type `T`.
The `S` parameter is a `Tuple`-type specifying the dimensions, or size, of the
`AbstractStaticShape` - such as `Tuple{3,4,5}` for a 3×4×5-sized shape.
"""
abstract type AbstractStaticShape{S,T,N} <: AbstractShape{T,N} end

const AbstractScalarShape{T} = AbstractStaticShape{Tuple{},T,0}
const AbstractVectorShape{S,T} = AbstractStaticShape{Tuple{S},T,1}
const AbstractMatrixShape{S1,S2,T} = AbstractStaticShape{Tuple{S1,S2},T,2}


# TODO StaticArrays.missing_size_error
StaticArrays.Size(s::AbstractStaticShape{S}) where {S<:Tuple} = Size(S)
Base.size(s::AbstractStaticShape) = Tuple(Size(s))

StaticArrays.Length(s::AbstractStaticShape) = Length(Size(s))
Base.length(s::AbstractStaticShape) = Int(Length(s))

Base.axes(s::AbstractStaticShape) = _axes(Size(s))
@pure _axes(::Size{sizes}) where {sizes} = map(SOneTo, sizes)


Base.similar(a::AbstractArray, s::AbstractStaticShape) = similar(a, eltype(s), Size(s))
function Base.similar(::Type{A}, s::AbstractStaticShape) where {A<:AbstractArray}
    similar(A, eltype(s), Size(s))
end

Base.reshape(a::AbstractArray, s::AbstractStaticShape) = reshape(a, Size(s))



StaticArrays.similar_type(a::AbstractArray, s::AbstractStaticShape) = similar_type(typeof(a), s)
function StaticArrays.similar_type(::Type{A}, s::AbstractStaticShape) where {A<:AbstractArray}
    similar_type(A, concrete_eltype(s), Size(s))
end

# TODO
#StaticArrays.SArray(s::AbstractStaticShape{S,T,N}, x...) where {S,T,N} = SArray{S,T,N}(x...)
#StaticArrays.MArray(s::AbstractStaticShape{S,T,N}, x...) where {S,T,N} = MArray{S,T,N}(x...)
#StaticArrays.MArray(s::AbstractStaticShape{S,T,N}, x...) where {S,T,N} = MArray{S,T,N}(x...)

# TODO UndefIntializer

function (::Type{SA})(s::AbstractStaticShape, x...) where {SA<:StaticArray}
    similar_type(SA, concrete_eltype(s), Size(s))(x...)
end
function (::Type{SA})(s::AbstractStaticShape, x...) where {SA<:SizedArray}
    similar_type(SA, concrete_eltype(s), Size(s))(x...)
end



# Something doesn't match up type wise
function check_staticshape_parameters(S, T, N)
    (!isa(S, DataType) || (S.name !== Tuple.name)) && argerror("Static Shape parameter S must be a Tuple-type, got $S")
    !isa(T, Type) && argerror("Static Shape parameter T must be a Type, got $T")
    !isa(N.parameters[1], Int) && argerror("Static Shape parameter N must be an Int, got $(N.parameters[1])")
    # shouldn't reach here. Anything else should have made it to the function below
    error("Internal error. Please file a bug")
end

@generated function check_staticshape_parameters(::Type{S}, ::Type{T}, ::Val{N}) where {S,T,N}
    if !all(x -> isa(x, Int), S.parameters)
        return :(argerror("Static Shape parameter S must be a Tuple-type of Ints (e.g. `Tuple{3,3}`). Got $S"))
    end

    if tuple_minimum(S) < 0 || tuple_length(S) != N
        return :(argerror("Size mismatch in Shapes parameters. Got size $S and dimension $N"))
    end

    return nothing
end



#####
##### SShape
#####

struct SShape{S<:Tuple,T,N} <: AbstractStaticShape{S,T,N}
    function SShape{S,T,N}() where {S<:Tuple,T,N}
        check_staticshape_parameters(S, T, Val(N))
        new{S,T,N}()
    end
end

const SScalarShape{T} = SShape{Tuple{},T,0}
const SVectorShape{S,T} = SShape{Tuple{S},T,1}
const SMatrixShape{S1,S2,T} = SShape{Tuple{S1,S2},T,2}

@generated function (::Type{SShape{S,T}})() where {S<:Tuple,T}
    return quote
        @_inline_meta
        SShape{S,T,$(tuple_length(S))}()
    end
end

# NOTE Can't @pure here since SShape has an error path
@inline SShape(::Type{T}) where {T} = SScalarShape{T}()
@inline SShape(::Type{T}, m::Int) where {T} = SVectorShape{m,T}()
@inline SShape(::Type{T}, m::Int, n::Int) where {T} = SMatrixShape{m,n,T}()
@inline SShape(::Type{T}, dims::Dims{N}) where {T,N} = SShape{tuple_to_size(dims),T,N}()
@inline SShape(::Type{T}, dims::Int...) where {T} = SShape(T, dims)

# TODO Test without
#ScalarSShape(T::Type) = SShape(T)
#VectorSShape(T::Type, dim::Integer) = SShape(T, dim)
#MatrixSShape(T::Type, d1::Integer, d2::Integer) = SShape(T, d1, d2)

@inline SShape(::Type{T}, S::Size) where {T} = SShape{size_tuple(S),T}()
@inline function SShape(A::AbstractArray{T,N}) where {T,N}
    size = size(A)
    check_dynamicsize(size)
    SShape{tuple_to_size(size),T,N}()
end

@pure tuple_to_size(S::TupleN{Int}) = Tuple{S...}

@inline check_dynamicsize(::Dims) = nothing
function check_dynamicsize(dims)
    # TODO note about DynamicSShape
    argerror("""
        Cannot create a StaticSShape from a dynamically sized array.
        """)
end

@inline Adapt.adapt_storage(::Type{V}, sh::SShape{S,T,N}) where {V,S,T,N} = SShape{S,V,N}()
