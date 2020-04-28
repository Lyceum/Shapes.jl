# For convenience
const TupleN{T,N} = NTuple{N,T}


# TODO For concrete type/eltype:
#   - handle other types
#   - check if isdefined
#   - check if isconcretetype
"""
    $(SIGNATURES)

Returns `T` if `T` is a concrete type, otherwise returns a default concrete type `U <: T`.
"""
concrete_type(T::Type) = argerror("Only `T <: Real` is currently supported")
concrete_type(T::Type{<:Real}) = _concrete_type(T)
_concrete_type(::Type{>:Int}) = Int
_concrete_type(::Type{>:Float64}) = Float64
_concrete_type(::Type{>:Real}) = Float64
_concrete_type(T::Type) = T

"""
    $(SIGNATURES)

Returns `eltype(T)` if `eltype(T)` is a concrete type, else a default type `U <: eltype(T)`.

See also: [`concrete_type`](@ref)
"""
concrete_eltype(::Type{T}) where {T} = concrete_type(eltype(T))


mapfoldl_recur_nt(f, op, t::NamedTuple) = mapfoldl(x -> mapfoldl_recur_nt(f, op, x), op, t)
mapfoldl_recur_nt(f, op, x) = f(x)

foldl_recur_nt(op, t::NamedTuple) = mapfoldl(identity, op, t)

map_recur_nt(f, t::NamedTuple) = map(x -> map_recur_nt(f, x), t)
map_recur_nt(f, x) = f(x)


# TODO Base.require_one_based_indexing
has_unit_axes(A) = all(ax->ax isa AbstractUnitRange{Int}, axes(A))
function check_has_unit_axes(A)
    has_unit_axes(A) || throw(ArgumentError("The axes of data must be <: AbstractUnitRange{Int}"))
end


#maybe_promote_eltype(T::Type, shape::AbstractShape) = promote_type(T, eltype(shape)) #TODO test
#maybe_promote_eltype(T::Type, x) = T


####
#### TODO Move the below to LyceumCore
####

argerror(msg::AbstractString) = throw(ArgumentError(msg))
dimerror(msg::AbstractString) = throw(DimensionMismatch(msg))


"""
    $(SIGNATURES)

Throws an error if the axes of `x` and `y` do not match.
"""
@inline function checkaxes(x, y)
    if !checkaxes(Bool, x, y)
        dimerror("Axes of $(typeof(x)) $(axes(x)) do not match axes of $(typeof(y)) $(axes(y))")
    end
end

"""
    $(SIGNATURES)

Return `true` if the axes of `x` and `y` match.
"""
@inline checkaxes(::Type{Bool}, x, y) = axes(x) == axes(y)


"""
    $(SIGNATURES)

Throws an error if the size of `x` and `y` do not match.
"""
@inline function checksize(x, y)
    if !checksize(Bool, x, y)
        dimerror("Size of $(typeof(x)) $(size(x)) do not match axes of $(typeof(y)) $(size(y))")
    end
end

"""
    $(SIGNATURES)

Return `true` if the size of `x` and `y` match.
"""
@inline checksize(::Type{Bool}, x, y) = axes(x) == axes(y)


@inline tuplecat(x) = x
@inline tuplecat(x, y) = (x..., y...)
@inline tuplecat(x, y, z...) = (x..., tuplecat(y, z...)...)
