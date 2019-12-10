function shapedview(N::Int)
    s1 = MatrixShape(Float64, 5,10)
    s2 = VectorShape(Float64, 15)
    s3 = ScalarShape(Float64)

    ms = MultiShape(s1 = s1, s2 = s2, s3=s3)
    src = rand!(allocate(ms, N))
    dst = zeros(ms, N)

    bench = @benchmarkable begin
        _shapedview_bench($ms, $src, $dst)
    end teardown=(@assert $src == $dst)

    base = @benchmarkable _shapedview_base($src, $dst)

    bench, base
end

function _shapedview_bench(ms, src, dst)
    @uviews src dst @inbounds for i in axes(src, 2)
        s, d = view(src, :, i), view(dst, :, i)
        ssv, dsv = ms(s), ms(d)

        dsv.s1 .= ssv.s1
        dsv.s2 .= ssv.s2
        dsv.s3 = ssv.s3
    end
end

function _shapedview_base(src, dst)
    @uviews src dst @inbounds for i in axes(src, 2)
        s, d = view(src, :, i), view(dst, :, i)
        s .= d
    end
end