struct ShapedView{SH,D<:AbstractVector}
    data::D
    offset::Int
    Base.@propagate_inbounds function ShapedView(
        data::AbstractVector,
        offset::Int,
        shape::AbstractShape,
    )
        @boundscheck check_shapedview_args(data, offset, shape)
        new{shape,typeof(data)}(data, offset)
    end
end

ShapedView(data::AbstractVector, shape::AbstractShape)  = ShapedView(data, 0, shape)
(s::MultiShape)(data) = ShapedView(data, s)


function Base.getproperty(sv::ShapedView{MS}, name::Symbol) where {MS}
    shape = getproperty(MS, name)
    offset = getoffset(MS, name)
    @inbounds ShapedView(getfield(sv, :data), offset, shape)
end


function Base.getindex(sv::ShapedView{SH}) where {SH}
    _getindex(getfield(sv, :data), getfield(sv, :offset), SH) # TODO @inbounds
end

@inline function _getindex(data::AbstractVector, offset::Int, shape::AbstractScalarShape)
    data[offset + firstindex(data)]
end
@inline function _getindex(data::AbstractVector, offset::Int, shape::AbstractVectorShape)
    view(data, (offset + firstindex(data)):(offset + length(shape)))
end
@inline function _getindex(data::AbstractVector, offset::Int, shape::AbstractShape)
    reshape(view(data, (offset + firstindex(data)):(offset + length(shape))), size(shape))
end


function Base.setindex!(sv::ShapedView{SH}, val) where {SH}
    data = getfield(sv, :data)
    offset = getfield(sv, :offset)
    _setindex(data, offset, SH, val) # TODO @inbounds
end

@inline function _setindex(data::AbstractVector, offset::Int, shape::ScalarShape, val)
    setindex!(data, val, firstindex(data) + offset)
end


function check_shapedview_args(data::AbstractVector, offset::Int, shape::AbstractShape)
    Base.require_one_based_indexing(data) # TODO, allow offset based indexing
    checkbounds(data, offset + firstindex(data))
    checkbounds(data, offset + length(shape))
end