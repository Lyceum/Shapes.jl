struct Composite{comps,S,T} <: AbstractVectorShape{S,T}
    function Composite{comps,S,T}() where {comps,S,T}
        #check_composite_params(Val(comps), S, T)
        new{comps,S,T}()
    end
end

@generated function (::Type{Composite{comps}})() where {components}
    check_components(comps) || return :(throw(ArgumentError("Invalid components")))
    S = mapfoldl_recur_nt(length, +, comps)
    T = mapfoldl_recur_nt(eltype, promote_type, comps)
    return quote
        @_inline_meta
        Composite{$comps,$S,$T}()
    end
end

# TODO Pairs? Dict?
Composite(comps::NamedTuple) = Composite{comps}()
Composite(; comps...) = Composite(values(comps))
Composite(Cs::Composite...) = Composite(foldl(merge, Cs))

iscomponents(comps::NamedTuple) = mapfoldl_recur_nt(iscomponent, &, comps)
iscomponent(::Size) = true
iscomponent(::TupleN{Integer}) = true
iscomponent(::AbstractShape) = true
iscomponent(::Any) = false

canonify_components(comps::NamedTuple) = map_recur_nt(canonify_component, comps)
canonify_component(dims::Dims) = dims
canonify_component(dims::TupleN{Integer}) = convert(Dims, dims)
canonify_component(size::Size) = Tuple(size)
canonify_component(x) = error("Unknown component type $x")


NamedTuple(C::Composite{comps}) where {comps} = comps

Base.getproperty(C::Composite, name::Symbol) = getfield(NamedTuple(C), name)
Base.propertynames(C::Composite) = propertynames(NamedTuple(C))
Base.keys(C::Composite) = keys(NamedTuple(C))
Base.values(C::Composite) = values(NamedTuple(C))
Base.merge(C::Composite...) = Composite(mapfoldl(NamedTuple, merge, C))


#@pure Adapt.adapt_storage(T::DataType, ::MS) where {MS <: Composite} = Composite(map(s->Adapt.adapt(T, s), get(MS)))

@pure shapeindex(ms::Composite, name::Symbol) = Base.fieldindex(typeof(get(ms)), name)

@pure Base.firstindex(ms::Composite) = firstindex(get(ms))
@pure Base.lastindex(ms::Composite) = lastindex(get(ms))

@pure Base.getindex(ms::Composite, i::Int) = getindex(get(ms), i)

@pure function getoffset(ms::Composite, name::Symbol)
    idx = shapeindex(ms, name)
    idx == firstindex(ms) ? 0 : sum(i -> length(ms[i]), 1:(idx-1))
end
