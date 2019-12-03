struct ShapedView{MS,D<:AbstractVector}
    data::D
    Base.@propagate_inbounds function ShapedView(
        data::AbstractVector,
        multishape::MultiShape,
    )
        @boundscheck if length(data) != length(multishape)
            error("length of `data` must be equal to the length of `multishape`")
            Base.require_one_based_indexing(data)
        end
        new{multishape,typeof(data)}(data)
    end
end

(s::MultiShape)(data) = ShapedView(data, s)

Base.getproperty(sv::ShapedView, name::Symbol) = getproperty(sv, Val(name))
@generated function Base.getproperty(sv::ShapedView{MS}, ::Val{name}) where {MS,name}
    shape = getproperty(MS, name)
    idxs = getindices(MS, name)
    if shape isa ScalarShape
        return quote
            @_inline_meta
            getfield(sv, :data)[$idxs]
        end
    elseif shape isa VectorShape
        return quote
            @_inline_meta
            view(getfield(sv, :data), $idxs)
        end
    else
        return quote
            @_inline_meta
            reshape(view(getfield(sv, :data), $idxs), $(size(shape)))
        end
    end
end

Base.setproperty!(sv::ShapedView, name::Symbol, val) = setproperty!(sv, Val(name), val)
@generated function Base.setproperty!(
    sv::ShapedView{MS},
    ::Val{name},
    val,
) where {MS,name}
    shape = getproperty(MS, name)
    if shape isa ScalarShape
        idxs = getindices(MS, name)
        return quote
            @_inline_meta
            setindex!(getfield(sv, :data), val, $idxs)
        end
    else
        msg = "Can only setproperty! on scalars, try ShapedView(data).shapename .= val (note the .=)"
        return :(error($msg))
    end
end