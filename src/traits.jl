"""
    abstract type AbstractShape{S, T, N, L} end

The supertype for the various concrete shapes defined by `Shapes`. The,/StaticArrays.jl).
The `S` parameter is a `Tuple`-type specifying the dimensions, or size, of the
`AbstractShape`- such as `Tuple{3,4,5}` for a 3×4×5-sized array. The `T` parameter
specifies the underlying data type of the shape (e.g. the element type for an array
shape). The `L` parameter is the length of the array and is always equal to `prod(S)`.
Constructors may drop the `L` and `T` parameters if they are inferrable from the input
(e.g. `L` is always inferrable from `S`).
"""
abstract type AbstractShape{S,T,N,L} end

const AbstractScalarShape{T} = AbstractShape{Tuple{},T}
const AbstractVectorShape{S,T} = AbstractShape{Tuple{S},T}
const AbstractMatrixShape{S1,S2,T} = AbstractShape{Tuple{S1,S2},T}

Size(::Type{SH}) where {SH<:AbstractShape{S}} where {S<:Tuple} = Size(S)
Size(shape::SH) where {SH<:AbstractShape} = Size(SH)

Length(::Type{SH}) where {SH<:AbstractShape} = Length(Size(SH))
Length(shape::SH) where {SH<:AbstractShape} = Length(typeof(shape))

Base.eltype(::Type{SH}) where {S<:Tuple,T,SH<:AbstractShape{S,T}} = T

@pure Base.length(::Type{SH}) where {SH<:AbstractShape} = get(Length(SH))
@inline Base.length(shape::AbstractShape) = length(typeof(shape))

@pure Base.size(::Type{SH}) where {SH<:AbstractShape} = get(Size(SH))
@inline function Base.size(T::Type{<:AbstractShape}, d::Int)
    S = size(T)
    d > length(S) ? 1 : S[d]
end
@inline Base.size(shape::AbstractShape) = size(typeof(shape))
@inline Base.size(shape::AbstractShape, d::Int) = size(typeof(shape), d)

@pure Base.ndims(::Type{SH}) where {S<:Tuple,T,N,SH<:AbstractShape{S,T,N}} = N
Base.ndims(shape::AbstractShape) = ndims(typeof(shape))

Base.axes(shape::AbstractShape) = _axes(Size(shape))
Base.axes(::Type{SH}) where {SH<:AbstractShape} = _axes(Size(SH))
@pure _axes(::Size{sizes}) where {sizes} = map(SOneTo, sizes)

@inline concrete_eltype(::Type{SH}) where {SH<:AbstractShape} = default_datatype(eltype(SH))
@inline concrete_eltype(shape::AbstractShape) = concrete_eltype(typeof(shape))


"""
    checkaxes(shape::AbstractShape, x)

Throws an error if `axes(shape) != axes(x)``.
"""
@inline function checkaxes(shape::AbstractShape, x)
    if !checkaxes(Bool, shape, x)
        throw(DimensionMismatch("axes(x) must be equal to axes(shape)"))
    end
end

"""
    checkaxes(Bool, shape::AbstractShape, x)

Return `true` if `axes(shape) == axes(x)``.
"""
@inline function checkaxes(::Type{Bool}, shape::AbstractShape, x::AbstractArray)
    axes(x) == axes(shape)
end
@inline checkaxes(::Type{Bool}, ::AbstractScalarShape, ::Number) = true

"""
    checksize(shape::AbstractShape, x)

Throws an error if `size(shape) != size(x)`.
"""
@inline function checksize(shape::AbstractShape, x)
    if !checksize(Bool, shape, x)
        throw(DimensionMismatch("size(x) must be equal to size(shape)"))
    end
end

"""
    checksize(Bool, shape::AbstractShape, x)

Return `true` if `size(shape) == size(x)`.
"""
@inline function checksize(::Type{Bool}, shape::AbstractShape, x::AbstractArray)
    size(shape) == size(x)
end
@inline checksize(::Type{Bool}, ::AbstractScalarShape, ::Number) = true


struct Shape{S,T,N,L} <: AbstractShape{S,T,N,L}
    function Shape{S,T,N,L}() where {S<:Tuple,T,N,L}
        check_shape_params(S, T, Val{N}, Val{L})
        new{S,T,N,L}()
    end
end

@generated function (::Type{Shape{S,T,N}})() where {S<:Tuple,T,N}
    return quote
        @_inline_meta
        Shape{S,T,N,$(tuple_prod(S))}()
    end
end

@generated function (::Type{Shape{S,T}})() where {S<:Tuple,T}
    return quote
        @_inline_meta
        Shape{S,T,$(tuple_length(S)),$(tuple_prod(S))}()
    end
end

Shape(T::Type) = ScalarShape{T}()
Shape(T::Type, dim::Integer) = VectorShape{convert(Int, dim), T}()
Shape(T::Type, d1::Integer, d2::Integer) = MatrixShape{convert(Int, d1), convert(Int, d2), T}()
function Shape(T::Type, d1::Integer, d2::Integer, d3::Integer)
    d1 = convert(Int, d1)
    d2 = convert(Int, d2)
    d3 = convert(Int, d3)
    Shape{Tuple{d1, d2, d3}, T}()
end
function Shape(T::Type, dims::Vararg{Int, N}) where N
    dims = convert(NTuple{N, Int}, dims)
    Shape{tuple_to_size(dims), T, N}()
end

const ScalarShape{T} = Shape{Tuple{},T}
const VectorShape{S,T} = Shape{Tuple{S},T}
const MatrixShape{S1,S2,T} = Shape{Tuple{S1,S2},T}

ScalarShape(T::Type) = Shape(T)
VectorShape(T::Type, dim::Integer) = Shape(T, dim)
MatrixShape(T::Type, d1::Integer, d2::Integer) = Shape(T, d1, d2)

Shape(S::Size, T::Type) = Shape{tuple_to_size(get(S)),T}()
Shape(::Type{A}) where {A<:AbstractArray} = Shape(Size(A), eltype(A))
function Shape(A::AbstractArray)
    size = get(Size(A))
    check_dynamicsize(size)
    Shape{tuple_to_size(size),eltype(A)}()
end

check_dynamicsize(::Dims) = nothing
function check_dynamicsize(::Tuple)
    throw(ArgumentError(
        """Cannot create Shape from dynamically sized Array.
        Try Shape(s::Size, T) or Shape(T, dims...) instead."""
    ))
end

Adapt.adapt_storage(T::DataType, sh::Shape{S}) where {S <: Tuple} = Shape{S,T}()



# TODO unneccesary type params
struct MultiShape{S,T,N,L,namedtuple} <: AbstractShape{S,T,N,L}
    function MultiShape{S,T,N,L,namedtuple}() where {S,T,N,L,namedtuple}
        check_multishape_params(S, T, Val{N}, Val{L}, Val{namedtuple})
        new{S,T,N,L,namedtuple}()
    end
end

@generated function (::Type{MultiShape{namedtuple}})() where {namedtuple}
    check_multishape_namedtuple(Val{namedtuple})
    ntlength = namedtuple_length(namedtuple)
    ntsize = Tuple{ntlength}
    nteltype = promote_namedtuple_eltype(namedtuple)
    return quote
        @_inline_meta
        MultiShape{$ntsize,$nteltype,1,$ntlength,$namedtuple}()
    end
end

MultiShape(nt::NamedTuple) = MultiShape{nt}()
MultiShape(; shapes...) = MultiShape(values(shapes))
MultiShape(ms::MultiShape; shapes...) = MultiShape(merge(NamedTuple(ms), shapes))
MultiShape(shapes::Pair{Symbol, <:AbstractShape}...) = MultiShape(; shapes...)

@pure get(::Type{SH}) where {SH<:MultiShape} = SH.parameters[end]
get(ms::MultiShape) = get(typeof(ms))

NamedTuple(::SH) where {SH<:MultiShape} = get(SH)

Base.getproperty(ms::MultiShape, name::Symbol) = getfield(NamedTuple(ms), name)
Base.propertynames(ms::MultiShape) = propertynames(NamedTuple(ms))
Base.keys(ms::MultiShape) = keys(NamedTuple(ms))
Base.values(ms::MultiShape) = values(NamedTuple(ms))
Base.merge(ms1::MultiShape, ms2::MultiShape) = MultiShape(merge(NamedTuple(ms1), NamedTuple(ms2)))


@pure function namedtuple_length(nt::NamedTuple{<:Any,<:Tuple{Vararg{AbstractShape}}})
    sum(shape -> get(Length(shape)), values(nt))
end

@generated function check_multishape_namedtuple(::Type{Val{namedtuple}}) where {namedtuple}
    if !(namedtuple isa NamedTuple)
        return :(throw(ArgumentError("MultiShape namedtuple parameter must be a namedtuple. Got: $namedtuple")))
    end

    if !all(x -> x isa AbstractShape, values(namedtuple))
        types = map(typeof, values(namedtuple))
        msg = "NamedTuple values must be AbstractShape. Got: $types"
        return :(throw(ArgumentError($msg)))
    end
end

@generated function check_multishape_params(
    ::Type{S},
    ::Type{T},
    ::Type{Val{N}},
    ::Type{Val{L}},
    ::Type{Val{namedtuple}},
) where {S,T,N,L,namedtuple}
    check_multishape_namedtuple(Val{namedtuple})
    check_shape_params(S, T, Val{N}, Val{L})

    ntlength = namedtuple_length(namedtuple)
    nteltype = promote_namedtuple_eltype(namedtuple)
    if !(nteltype <: T)
        msg = "Type mismatch in MultiShape parameters. Got type $T but promoted type of shapes was $nteltype"
        return :(throw(ArgumentError($msg)))
    end
    if L != ntlength
        msg = "Size mismatch in MultiShape parameters. Got length $L but sum of Shape lengths was $ntlength"
        return :(throw(ArgumentError($msg)))
    end
end

@pure Adapt.adapt_storage(T::DataType, ::MS) where {MS <: MultiShape} = MultiShape(map(s->Adapt.adapt(T, s), get(MS)))

@pure shapeindex(ms::MultiShape, name::Symbol) = Base.fieldindex(typeof(get(ms)), name)

@pure Base.firstindex(ms::MultiShape) = firstindex(get(ms))
@pure Base.lastindex(ms::MultiShape) = lastindex(get(ms))

@pure Base.getindex(ms::MultiShape, i::Int) = getindex(get(ms), i)

@pure function getoffset(ms::MultiShape, name::Symbol)
    idx = shapeindex(ms, name)
    idx == firstindex(ms) ? 0 : sum(i -> length(ms[i]), 1:(idx-1))
end