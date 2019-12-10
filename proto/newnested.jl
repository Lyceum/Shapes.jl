module M
using Shapes, MacroTools
using Base: @_inline_meta, @generated, @pure

# TODO TupleN
function Base.getindex(sv::ShapedView, i1::Symbol, I::Symbol...)
    _getindex(sv, Val{i1}(), Val{I}())
end

@generated function _getindex(sv::ShapedView{MS}, ::Val{i1}, ::Val{I}) where {MS, i1, I}
    shape, offset = _get_shape_and_offset(MS, 0, i1, I...)
    from = 1 + offset
    to = from + length(shape) - 1

    #if shape isa ScalarShape
        return quote
            @_inline_meta
            getfield(sv, :data)[$from]
        end
    #elseif shape isa VectorShape || shape isa MultiShape
    #    return quote
    #        @_inline_meta
    #        view(getfield(sv, :data), $from:$to)
    #    end
    #else
    #    return quote
    #        @_inline_meta
    #        reshape(view(getfield(sv, :data), $from:$to), $(size(shape)))
    #    end
    #end
end

@pure function _get_shape_and_offset(ms::MultiShape, offset::Int, i1::Symbol, I::Symbol...)
    shape = getproperty(ms, i1)
    offset += _getoffset(ms, i1)
    _get_shape_and_offset(shape, offset, I...)
end
_get_shape_and_offset(shape::AbstractShape, offset::Int) = shape, offset

@pure function _getoffset(ms::MultiShape, shapename::Symbol)
    nt = Shapes.get(ms) # TODO
    shapeidx = Base.fieldindex(typeof(nt), shapename)
    shapes = values(ms)
    shapeidx == 1 ? 0 : sum(i -> length(shapes[i]), 1:(shapeidx-1))
end

end

using .M
using Shapes, MacroTools

function test()
    s1 = MatrixShape{5,10,Real}()
    s2 = VectorShape{5,Float32}()
    s3 = ScalarShape{Int}()
    ms1 = MultiShape(s1 = s1, s2 = s2, s3=s3)

    s4 = VectorShape{3,Float32}()
    s5 = ScalarShape{Int}()
    ms2 = MultiShape(s4=s4, s5=s5)

    s6 = ScalarShape{Float64}()
    ms3 = MultiShape(s6=s6, ms2=ms2)

    ms = MultiShape(ms1=ms1, ms2=ms2, ms3=ms3)

    x = collect(1:length(ms))
    sv = ms(x)

    @code_warntype foo(sv)
    foo(sv)
end


foo(sv) = sv[:ms1, :s3]
foo(sv) = sv[:ms1, :s3]