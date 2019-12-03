using Shapes
using Test
using StaticArrays
using Shapes: concrete_eltype, ShapedView

@testset "Shapes.jl" begin

    @testset "Shape" begin
        @test ScalarShape{Int}() === Shape{Tuple{},Int}()
        @test VectorShape{5,Int}() === Shape{Tuple{5},Int}()
        @test MatrixShape{5,10,Int}() === Shape{Tuple{5,10},Int}()

        @test ScalarShape(Int) === Shape{Tuple{},Int}()
        @test VectorShape(Int, 5) === Shape{Tuple{5},Int}()
        @test MatrixShape(Int, 5, 10) === Shape{Tuple{5,10},Int}()
        @test Shape(Int, 1,2,3,4,5,6,7) === Shape{Tuple{1,2,3,4,5,6,7}, Int, 7, 5040}()

        s = MatrixShape{5,10,Real}()
        @test @inferred(Size(typeof(s))) === @inferred(Size(s)) === Size(5, 10)
        @test @inferred(Length(typeof(s))) === @inferred(Length(s)) === Length(50)
        @test @inferred(eltype(typeof(s))) === @inferred(eltype(s)) === Real
        @test @inferred(length(typeof(s))) === @inferred(length(s)) === 50

        @test @inferred(size(typeof(s))) === @inferred(size(s)) === (5, 10)
        @test @inferred(size(typeof(s), 1)) === @inferred(size(s, 1)) === 5
        @test @inferred(size(typeof(s), 2)) === @inferred(size(s, 2)) === 10

        @test @inferred(ndims(typeof(s))) === @inferred(ndims(s)) === 2
        @test @inferred(axes(typeof(s))) === @inferred(axes(s)) === (SOneTo(5), SOneTo(10))
        @test @inferred(concrete_eltype(typeof(s))) === @inferred(concrete_eltype(s)) ===
              Float64
    end

    @testset "MultiShape" begin
        s1 = MatrixShape{5,10,Real}()
        s2 = VectorShape{5,Float32}()
        s3 = ScalarShape{Int}()
        s = MultiShape(s1 = s1, s2 = s2, s3=s3)

        @test MultiShape(s, s4=s3).s3 === s3
        let s4 = MatrixShape(Float64, 1,2), ms = MultiShape(s4=s4)
            @test merge(s, ms).s4 === s4
        end

        @test s.s1 === s1
        @test s.s2 === s2
        @test s.s3 === s3
        @test NamedTuple(s) isa NamedTuple
        @test NamedTuple(s) === typeof(s).parameters[end]
        @test @inferred(propertynames(s)) === propertynames(NamedTuple(s))
        @test @inferred(values(s)) == values(NamedTuple(s))

        @test @inferred(Size(typeof(s))) === @inferred(Size(s)) === Size(56)
        @test @inferred(Length(typeof(s))) === @inferred(Length(s)) === Length(56)
        @test @inferred(eltype(typeof(s))) === @inferred(eltype(s)) === Real
        @test @inferred(length(typeof(s))) === @inferred(length(s)) === 56
        @test @inferred(size(typeof(s))) === @inferred(size(s)) === (56,)
        @test @inferred(ndims(typeof(s))) === @inferred(ndims(s)) === 1
        @test @inferred(axes(typeof(s))) === @inferred(axes(s)) === (SOneTo(56),)
        @test @inferred(concrete_eltype(typeof(s))) === Float64
        @test @inferred(concrete_eltype(s)) === Float64


    end

    @testset "StaticArrays support" begin
        svec = SVector(1, 2, 3)
        mvec = MVector(1, 2, 3)
        sizedvec = SizedVector{3}(1, 2, 3)

        @test @inferred(Shape(svec)) === Shape{Tuple{3},Int,1,3}()
        @test @inferred(Shape(mvec)) === Shape{Tuple{3},Int,1,3}()
        @test @inferred(Shape(sizedvec)) === Shape{Tuple{3},Int,1,3}()

        s1 = Shape(svec)
        s2 = Shape{Tuple{3},Integer,1,3}()
        @test @inferred(similar_type(s1)) === @inferred(similar_type(s2)) === typeof(svec)
        @test @inferred(similar_type(MArray, s1)) ===
              @inferred(similar_type(MArray, s2)) === typeof(mvec)

    end

    @testset "Array constructors" begin
        let s = VectorShape{5,Real}()
            @test @inferred(Array(undef, s)) isa Vector{Float64}
            @test @inferred(Array{Float64}(undef, s)) isa Vector{Float64}
            @test size(Array{Float64}(undef, s)) == (5,)
            @test size(allocate(s)) == (5,)

            @test @inferred(Array(undef, s, 10)) isa Matrix{Float64}
            @test @inferred(Array{Float64}(undef, s, 10)) isa Matrix{Float64}
            @test size(Array{Float64}(undef, s, 10)) == (5, 10)
            @test size(allocate(s, 10)) == (5, 10)

            @test @inferred(zeros(s)) == zeros(Float64, 5)
            @test @inferred(zeros(s, 10)) == zeros(Float64, 5, 10)
        end

        let s = MatrixShape{5,10,Real}()
            @test @inferred(Array(undef, s)) isa Matrix{Float64}
            @test @inferred(Array{Float64}(undef, s)) isa Matrix{Float64}
            @test size(Array{Float64}(undef, s)) == (5, 10)
            @test size(allocate(s)) == (5, 10)

            @test @inferred(Array(undef, s, 15)) isa Array{Float64,3}
            @test @inferred(Array{Float64}(undef, s, 15)) isa Array{Float64,3}
            @test size(Array{Float64}(undef, s, 15)) == (5, 10, 15)
            @test size(allocate(s, 15)) == (5, 10, 15)

            @test @inferred(zeros(s)) == zeros(Float64, 5, 10)
            @test @inferred(zeros(s, 15)) == zeros(Float64, 5, 10, 15)
        end
    end

    @testset "ShapedView" begin
        ms = MultiShape(
            x = MatrixShape{5,5,Int}(),
            y = ScalarShape{Float64}(),
            z = VectorShape{2,Float64}(),
        )
        lx = length(ms.x)
        ly = length(ms.y)
        lz = length(ms.z)
        d = Float64.(collect(1:(lx + ly + lz)))
        sv = ms(d)

        x(sv) = sv.x
        y(sv) = sv.y
        z(sv) = sv.z
        @test @inferred(x(sv)) === reshape(view(d, 1:lx), size(ms.x))
        @test @inferred(y(sv)) === d[1+lx]
        @test @inferred(z(sv)) === view(d, (1 + lx + ly):(lx + ly + lz))

        d1 = rand(1:100, 5, 5)
        d2 = rand()
        d3 = rand(2)

        sv.x .= d1
        sv.y = d2
        sv.z .= d3

        @test sv.x == d1
        @test sv.y == d2
        @test sv.z == d3
    end
end
