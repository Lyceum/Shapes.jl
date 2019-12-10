@testset "basic" begin
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

    x(sv) = sv.x[]
    y(sv) = sv.y[]
    z(sv) = sv.z[]
    @test @inferred(x(sv)) === reshape(view(d, 1:lx), size(ms.x))
    @test @inferred(y(sv)) === d[1+lx]
    @test @inferred(z(sv)) === view(d, (1 + lx + ly):(lx + ly + lz))

    d1 = rand(1:100, 5, 5)
    d2 = rand()
    d3 = rand(2)

    sv.x[] .= d1
    sv.y[] = d2
    sv.z[] .= d3

    @test sv.x[] == d1
    @test sv.y[] == d2
    @test sv.z[] == d3
end

@testset "nested" begin

end