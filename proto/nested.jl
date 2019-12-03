#include("../src/Shapes.jl")
using Shapes

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

getmultishape(::ShapedView{MS}) where MS = MS

gindices(ms::MultiShape, shapename::Symbol) = computeidxsimpl(ms, shapename, getproperty(ms, shapename))
function computeidxsimpl(ms::MultiShape, shapename::Symbol, shape::AbstractShape)
    nt = get(ms)
    shapeidx = Base.fieldindex(typeof(nt), shapename)
    shapes = values(ms)
    from = shapeidx == 1 ? 1 : 1 + sum(i -> length(shapes[i]), 1:(shapeidx-1))
    ifelse(shape isa ScalarShape, from, from:(from+length(shape)-1))
end

goffset(ms::MultiShape, shapename::Symbol) = goffsetimpl(ms, shapename, getproperty(ms, shapename))
function goffsetimpl(ms::MultiShape, shapename::Symbol, shape::AbstractShape)
    nt = Shapes.get(ms)
    shapeidx = Base.fieldindex(typeof(nt), shapename)
    shapes = values(ms)
    from = shapeidx == 1 ? 1 : 1 + sum(i -> length(shapes[i]), 1:(shapeidx-1))
    return from
    #ifelse(shape isa ScalarShape, from, from:(from+length(shape)-1))
end


gidx(x::ShapedView) = getfield(x, :data)

function Base.getindex(sv::ShapedView, i1, I...)
    ms = getmultishape(sv)
    data = getfield(sv, :data)
    _getindex(data, ms, i1, I...)
end

function _getindex(data, ms::MultiShape, i1, I...)
    shape = getproperty(ms, i1)
    offset = goffset(ms, i1)
    data = view(data, offset:(offset + length(shape) - 1))
    _getindex(data, shape, I...)
end
_getindex(data, ::AbstractShape) = data


