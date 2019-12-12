@testset "basic" begin
    let A=rand(10)
        s1 = VectorShape(Float64, 10)
        s2 = VectorShape(Float64, 11)
        @test_throws ArgumentError ShapedView(A, -1, s1)
        @test_throws ArgumentError ShapedView(A, 11, s1)
        @test_throws ArgumentError ShapedView(A, 0, s2)
    end


    ms = MultiShape(
        x = MatrixShape(Int,5,5),
        y = ScalarShape(Float64),
        z = VectorShape(Float64, 2),
    )
    lx = length(ms.x)
    ly = length(ms.y)
    lz = length(ms.z)
    d = Float64.(collect(1:(lx + ly + lz)))
    sv = ms(d)

    x(sv) = sv.x
    y(sv) = sv.y
    z(sv) = sv.z
    @test @inferred(x(sv)) == reshape(view(d, 1:lx), size(ms.x))
    @test @inferred(y(sv)) === d[1+lx]
    @test @inferred(z(sv)) == view(d, (1 + lx + ly):(lx + ly + lz))

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

(s1=rand(5,10), s2=rand(5), )

@testset "nested" begin
    s1 = MatrixShape(Real,5,10)
    s2 = VectorShape(Float32,5)
    s3 = ScalarShape(Int)
    ms1 = MultiShape(s1 = s1, s2 = s2, s3=s3)

    s4 = VectorShape(Float32,3)
    s5 = ScalarShape(Int)
    ms2 = MultiShape(s4=s4, s5=s5)

    s6 = ScalarShape(Float64)
    ms3 = MultiShape(s6=s6, ms2=ms2)

    ms = MultiShape(ms1=ms1, ms2=ms2, ms3=ms3)
    x = collect(1:length(ms))
    sv = ms(x)

    @test sv.ms1 == 1:56
    @test vec(sv.ms1.s1) == 1:50
    @test vec(sv.ms1.s2) == 51:55
    @test sv.ms1.s3 == 56

    @test vec(sv.ms2.s4) == 57:59
    @test sv.ms2.s5 == 60

    @test sv.ms3.s6 == 61
    @test vec(sv.ms3.ms2.s4) == 62:64
    @test sv.ms3.ms2.s5 == 65
end