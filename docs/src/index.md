# Overview

**Shapes** provides Julia [traits](https://docs.julialang.org/en/latest/manual/methods/#Trait-based-dispatch-1) for
describing the shape of a value, like a scalar or array.

Shapes can be used for pre-allocating storage and allows for viewing flat, unstructured data (e.g. a `Vector{Float64}`)
as a set of variables, each with their own shapes and data types.

Shapes is _heavily_ inspired by [ValueShapes](https://github.com/oschulz/ValueShapes.jl)
and [StaticArrays](https://github.com/JuliaArrays/StaticArrays.jl); it is essentially a
statically-sized version of the former, allowing for zero-cost abstractions.

## Shape and MultiShape

The core type provided by Shapes.jl is [`Shape{S,T,N,L}`](@ref Shapes.Shape), where
`S`, `T`, `N`, and `L` describe the size, data type, dimensionality, and overall length
of the shape, respectively. [`ScalarShape{T}`](@ref Shapes.ScalarShape),
[`VectorShape{T, L}`](@ref Shapes.VectorShape),
and [`MatrixShape{M, N, T}`](@ref Shapes.MatrixShape) aliases are provided for convenience.


```jldoctest basic
julia> using Shapes

julia> shape = MatrixShape(Float64, 5, 10)
Shape{Tuple{5,10},Float64,2,50}()
```

Shapes can be used with a variety of `Base` functions to describe different
aspects of the `Shape`:
```jldoctest basic
julia> size(shape) == (5, 10) && length(shape) == 50 && ndims(shape) == 2
true
julia> axes(shape) # Shapes uses the static ranges provided by StaticArrays.jl
(SOneTo(5), SOneTo(10))
```

Shapes also distinguish between its possibly abstract data type
and the underlying concrete storage type:
```jldoctest basic
julia> shape = VectorShape(Real, 5);

julia> eltype(shape)
Real

julia> concrete_eltype(shape) # The default for T, where Real <: T <: Number, is Float64.
Float64
```

This can be used for pre-allocating concrete storage for a `Shape`:
```jldoctest basic
julia> x = Array(undef, shape, 100);

julia> typeof(x)
Array{Float64,2}

julia> size(x)
(5, 100)
```

Shapes also provides [`MultiShape{S,T,N,L}`](@ref Shapes.MultiShape), which behaves
as a `NamedTuple` of shapes and can be used to represent a collection of variables
or parameters:
```jldoctest basic
julia> multishape = MultiShape(x = ScalarShape(Real), y = VectorShape(Float64, 3))
MultiShape{Tuple{4},Real,1,4,(x = Shape{Tuple{},Real,0,1}(), y = Shape{Tuple{3},Float64,1,3}())}()

julia> multishape.y
Shape{Tuple{3},Float64,1,3}()
```

## ShapedView

Perhaps the most useful feature of Shapes.jl is `ShapedView`, which provides
a structured view of flat numerical data:

```jldoctest basic; output=false
using Random

xshape = ScalarShape(Real);
yshape = MatrixShape(Real, 5, 10);
multishape = MultiShape(x=xshape, y=yshape);

xdata = rand(xshape);
ydata = rand(yshape);
flatdata = [xdata, ydata...];

shapedview = multishape(flatdata);

@assert shapedview.x == xdata == flatdata[1]
shapedview.x = 10
@assert shapedview.x == 10

@assert shapedview.y == ydata
@assert shapedview.y === reshape(view(flatdata, 2:length(flatdata)), size(yshape))

# output

```

```@meta
DocTestSetup = nothing
```