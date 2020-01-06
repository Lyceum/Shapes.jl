# TODO require that T <: U?
struct ShapedView{T,N,SH,D<:AbstractVector{T}} <: DenseArray{T,N}
    data::D
    offset::Int
    Base.@propagate_inbounds function ShapedView{T,N,SH,D}(
        data::D,
        offset::Int
    ) where {T,N,SH,D<:AbstractVector{T}}
        @boundscheck check_offset_shape_inbounds(data, offset, SH)
        check_has_unit_axes(data)
        SH isa AbstractShape || throw(ArgumentError("Type parameter SH must be <: AbstractShape"))
        new{T,N,SH,D}(data, offset)
    end
end

function ShapedView{T,N,SH}(data, offset) where {T,N,SH}
    ShapedView{T,N,SH,typeof(data)}(data, offset)
end

function ShapedView(data::AbstractVector, offset::Int, shape::AbstractShape)
    ShapedView{eltype(data), ndims(shape), shape, typeof(data)}(data, offset)
end

function ShapedView(data::AbstractVector, shape::AbstractShape)
    ShapedView{eltype(data), ndims(shape), shape, typeof(data)}(data, 0)
end

ShapedView(data, shape) = ShapedView(data, 0, shape)

(s::AbstractShape)(data) = ShapedView(data, 0, s)


@pure shapeof(::Type{SV}) where {T,N,SH,SV <: ShapedView{T,N,SH}} = SH
@inline shapeof(A::ShapedView) = shapeof(typeof(A))

@pure Size(::Type{SV}) where {SV <: ShapedView} = Size(shapeof(SV))
@inline Size(A::ShapedView) = Size(typeof(A))

@pure Length(::Type{SV}) where {SV <: ShapedView} = Length(shapeof(SV))
@inline Length(A::ShapedView) = Length(typeof(A))

@pure Base.size(::Type{SV}) where {SV <: ShapedView} = size(shapeof(SV))
@inline Base.size(A::ShapedView) = size(typeof(A))

@pure Base.length(::Type{SV}) where {SV <: ShapedView} = length(shapeof(SV))
@inline Base.length(A::ShapedView) = length(typeof(A))

@pure Base.ndims(::Type{SV}) where {SV <: ShapedView} = ndims(shapeof(SV))
@inline Base.ndims(A::ShapedView) = ndims(typeof(A))

@pure Base.axes(::Type{SV}) where {SV <: ShapedView} = axes(shapeof(SV))
@inline Base.axes(A::ShapedView) = axes(typeof(A))

@pure Base.IndexStyle(::Type{SV}) where {SV <: ShapedView} = IndexLinear()
@inline Base.IndexStyle(A::ShapedView) = IndexStyle(typeof(A))

@pure Base.propertynames(::Type{SV}) where {SV <: ShapedView} = propertynames(shapeof(SV))
@inline Base.propertynames(A::ShapedView) = propertynames(typeof(A))

function Base.unsafe_convert(::Type{Ptr{T}}, A::ShapedView{T}) where {T}
    Base.unsafe_convert(Ptr{T}, _data(A))
end

Base.dataids(A::ShapedView) = Base.dataids(_data(A))

function Base.copy(A::ShapedView{T,N,SH}) where {T,N,SH}
    ShapedView{T,N,SH}(copy(_data(A)), _offset(A))
end


@propagate_inbounds function Base.getproperty(A::ShapedView, name::Symbol)
    shape = shapeof(A)
    offset = _offset(A) + getoffset(shape, name)
    innershape = getproperty(shape, name)
    _maybe_shapedview(_data(A), offset, innershape)
end

@propagate_inbounds function _maybe_shapedview(data, offset, ::AbstractScalarShape)
    i = offset + firstindex(data)
    @boundscheck checkbounds(data, i)
    @inbounds getindex(data, i)
end

@propagate_inbounds function _maybe_shapedview(data, offset, shape)
    @boundscheck check_offset_shape_inbounds(data, offset, shape)
    @inbounds ShapedView{eltype(data), ndims(shape), shape, typeof(data)}(data, offset)
end


@propagate_inbounds function Base.setproperty!(A::ShapedView, name::Symbol, x)
    innershape = getproperty(shapeof(A), name)
    _maybe_setproperty!(innershape, A, name, x)
end

@propagate_inbounds function _maybe_setproperty!(shape::AbstractScalarShape, A, name, x)
    offset = _offset(A) + getoffset(shapeof(A), name)
    data = _data(A)
    i = firstindex(data) + offset
    @boundscheck checkbounds(data, i)
    @inbounds setindex!(data, x, i)
end

@inline function _maybe_setproperty!(shape::AbstractShape, A, name, x)
    error("Cannot call `setproperty!` for shape $name of type $(typeof(shape))")
end


@propagate_inbounds function Base.getindex(A::ShapedView, i::Int)
    data = _data(A)
    i += _offset(A)
    @boundscheck checkbounds(data, i)
    @inbounds getindex(data, i)
end

@propagate_inbounds function Base.setindex!(A::ShapedView, val, i::Int)
    data = _data(A)
    i += _offset(A)
    @boundscheck checkbounds(data, i)
    @inbounds setindex!(data, val, i)
end


function UnsafeArrays.unsafe_uview(A::ShapedView{T,N,SH}) where {T,N,SH}
    @inbounds ShapedView{T,N,SH}(UnsafeArrays.unsafe_uview(_data(A)), _offset(A))
end

function check_offset_shape_inbounds(data::AbstractVector{T}, offset::Int, shape::AbstractShape{S,U,N}) where {T,S,U,N}
    if length(shape) > 0 && !(0 <= offset < length(data))
        throw(ArgumentError("offset must be in range [0, length(data))"))
    end
    if length(data) < offset + length(shape)
        throw(ArgumentError("offset + length(shape) cannot be greater than length(data)"))
    end
end

@inline _data(A::ShapedView) = getfield(A, :data)
@inline _offset(A::ShapedView) = getfield(A, :offset)