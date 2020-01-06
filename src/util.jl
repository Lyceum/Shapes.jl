"""
    tuple_to_size(::Type{S}) where S<:Tuple
Converts a tuple given by `(N, M, ...)` into `Tuple{N, M, ...}`.
"""
Base.@pure tuple_to_size(S::Tuple{Vararg{Int}}) = Tuple{S...}

# Copied (with modifications) from StaticArrays.jl
@generated function check_shape_params(
    ::Type{S},
    ::Type{T},
    ::Type{Val{N}},
    ::Type{Val{L}},
) where {S,T,N,L}
    if !all(x -> isa(x, Int), S.parameters)
        return :(throw(ArgumentError("Shapes parameter S must be a tuple of Ints (e.g. `Tuple{3,3}`")))
    end

    if L != tuple_prod(S) || L < 0 || tuple_minimum(S) < 0 || tuple_length(S) != N
        return :(throw(ArgumentError("Size mismatch in Shapes parameters. Got size $S, dimension $N and length $L.")))
    end

    return nothing
end

@generated function promote_namedtuple_eltype(::Union{NT,Type{NT}}) where {NT<:NamedTuple}
    #eltypes = map(eltype, shapes.parameters)
    eltypes = Tuple(eltype(shape) for shape in NT.parameters[2].parameters)
    T = promote_tuple_eltype(Tuple{eltypes...})
    return quote
        @_inline_meta
        $T
    end
end


# Copied from ValueShapes.jl
"""
    Shapes.default_datatype(T::Type)
Return a default specific type U that is more specific than T, with U <: T.
e.g.
    Shapes.default_datatype(Real) === Float64
    Shapes.default_datatype(Integer) === Int
"""
function default_datatype end

@inline default_datatype(T::Type) = throw(ArgumentError("Type must be <: Real. Got $T."))
@inline default_datatype(T::Type{<:Real}) = _default_datatype(T)
@inline _default_datatype(::Type{>:Int}) = Int
@inline _default_datatype(::Type{>:Float64}) = Float64
@inline _default_datatype(::Type{>:Real}) = Float64
@inline _default_datatype(T::Type) = T



has_unit_axes(A) = all(ax->ax isa AbstractUnitRange{Int}, axes(A))
function check_has_unit_axes(A)
    has_unit_axes(A) || throw(ArgumentError("The axes of data must be <: AbstractUnitRange{Int}"))
end
