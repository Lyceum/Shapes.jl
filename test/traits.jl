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

@testset "checkaxes" begin
    @test @inferred(checkaxes(VectorShape(Float64, 2), rand(2))) === nothing
    @test checkaxes(ScalarShape(Float64), 2) === nothing
    @test_throws DimensionMismatch checkaxes(VectorShape(Float64, 2), rand(3))
    @test_throws DimensionMismatch checkaxes(ScalarShape(Float64), rand(2))

    @test_throws MethodError checkaxes(ScalarShape(Float64), "not a Number")
    @test_throws MethodError checkaxes(VectorShape(Float64, 2), "not an AbstractArray")
    @test_throws MethodError checkaxes(ScalarShape(Float64), "not a Number")
    @test_throws MethodError checkaxes(VectorShape(Float64, 2), "not an AbstractArray")

    @test @inferred(Bool, checkaxes(Bool, VectorShape(Float64, 2), rand(2))) == true
    @test checkaxes(Bool, ScalarShape(Float64), 2) == true
    @test checkaxes(Bool, VectorShape(Float64, 2), rand(3)) == false
    @test checkaxes(Bool, ScalarShape(Float64), rand(2)) == false

    @test_throws MethodError checkaxes(Bool, ScalarShape(Float64), "not a Number")
    @test_throws MethodError checkaxes(Bool, VectorShape(Float64, 2), "not an AbstractArray")
    @test_throws MethodError checkaxes(Bool, ScalarShape(Float64), "not a Number")
    @test_throws MethodError checkaxes(Bool, VectorShape(Float64, 2), "not an AbstractArray")
end

@testset "checksize" begin
    @test @inferred(checksize(VectorShape(Float64, 2), rand(2))) === nothing
    @test checksize(ScalarShape(Float64), 2) === nothing
    @test_throws DimensionMismatch checksize(VectorShape(Float64, 2), rand(3))
    @test_throws DimensionMismatch checksize(ScalarShape(Float64), rand(2))

    @test_throws MethodError checksize(ScalarShape(Float64), "not a Number")
    @test_throws MethodError checksize(VectorShape(Float64, 2), "not an AbstractArray")
    @test_throws MethodError checksize(ScalarShape(Float64), "not a Number")
    @test_throws MethodError checksize(VectorShape(Float64, 2), "not an AbstractArray")

    @test @inferred(Bool, checksize(Bool, VectorShape(Float64, 2), rand(2))) == true
    @test checksize(Bool, ScalarShape(Float64), 2) == true
    @test checksize(Bool, VectorShape(Float64, 2), rand(3)) == false
    @test checksize(Bool, ScalarShape(Float64), rand(2)) == false

    @test_throws MethodError checksize(Bool, ScalarShape(Float64), "not a Number")
    @test_throws MethodError checksize(Bool, VectorShape(Float64, 2), "not an AbstractArray")
    @test_throws MethodError checksize(Bool, ScalarShape(Float64), "not a Number")
    @test_throws MethodError checksize(Bool, VectorShape(Float64, 2), "not an AbstractArray")
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
