using Shapes
using Test
using StaticArrays
using Shapes: concrete_eltype, ShapedView

@testset "Shapes.jl" begin

    @testset "traits" begin include("traits.jl") end

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

    @testset "default_datatype" begin
        @test @inferred(Shapes.default_datatype(Integer)) == Int
        @test @inferred(Shapes.default_datatype(Int32)) == Int32
        @test @inferred(Shapes.default_datatype(AbstractFloat)) == Float64
        @test @inferred(Shapes.default_datatype(Real)) == Float64
        @test @inferred(Shapes.default_datatype(Float32)) == Float32
        @test @inferred(Shapes.default_datatype(Real)) == Float64
        @test_throws ArgumentError Shapes.default_datatype(Complex)
    end

    @testset "check size/axes" begin
        A = rand(2,4,6)

        @test @inferred(checkaxes(Shape(Float64, 2, 4, 6), rand(2,4,6))) isa Bool
        @test_throws ArgumentError checkaxes(Shape(Float64, 2, 6, 6), rand(2,4,6)) isa Bool
        @test_throws ArgumentError checkaxes(Shape(Float64, 2, 6), rand(2,4,6)) isa Bool

        @test @inferred(checksize(Shape(Float64, 2, 4, 6), rand(2,4,6))) isa Bool
        @test_throws ArgumentError checksize(Shape(Float64, 2, 6, 6), rand(2,4,6)) isa Bool
        @test_throws ArgumentError checksize(Shape(Float64, 2, 6), rand(2,4,6)) isa Bool
    end
end