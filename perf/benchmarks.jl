#function sv_ms_assign_loop(N::Int)
#    s1 = MatrixShape(Float64, 5,10)
#    s2 = VectorShape(Float64, 15)
#    s3 = ScalarShape(Float64)
#
#    ms = MultiShape(s1 = s1, s2 = s2, s3=s3)
#    src = rand!(allocate(ms, N))
#    dst = zeros(ms, N)
#
#    bench = @benchmarkable begin
#        sv_ms_assign_loop_bench($ms, $src, $dst)
#    end teardown=(@assert $src == $dst)
#
#    std = @benchmarkable sv_assign_loop_std($src, $dst)
#
#    bench, std
#end
#
#function sv_ms_assign_loop_bench(ms, src, dst)
#    @uviews src dst @inbounds for i in axes(src, 2)
#        s, d = view(src, :, i), view(dst, :, i)
#        src, dst = ms(s), ms(d)
#
#        dst.s1 .= src.s1
#        dst.s2 .= src.s2
#        dst.s3 = src.s3
#    end
#end
#
#function sv_ms_assign_loop_std(src, dst)
#    @uviews src dst @inbounds for i in axes(src, 2)
#        s, d = view(src, :, i), view(dst, :, i)
#        s .= d
#    end
#end


function sv_ms_nested_assign()
    s1 = MatrixShape(Float64,5,10)
    s2 = VectorShape(Float64,5)
    s3 = ScalarShape(Float64)
    ms1 = MultiShape(s1 = s1, s2 = s2, s3=s3)

    s4 = VectorShape(Float64,3)
    s5 = ScalarShape(Float64)
    ms2 = MultiShape(s4=s4, s5=s5)

    s6 = ScalarShape(Float64)
    ms3 = MultiShape(s6=s6, ms2=ms2)

    ms = MultiShape(ms1=ms1, ms2=ms2, ms3=ms3)

    src = rand!(allocate(ms))
    shaped_src = ms(rand!(allocate(ms)))
    dst = zeros(ms)
    shaped_dst = ms(zeros(ms))

    bench = @benchmarkable begin
        sv_ms_nested_assign_bench($shaped_dst, $shaped_src)
    end teardown=(@assert $shaped_dst == $shaped_src)

    std = @benchmarkable begin
        sv_ms_nested_assign_std($dst, $src)
    end teardown = (@assert $dst == $src)

    bench, std
end

function sv_ms_nested_assign_bench(dst, src)
    @uviews dst src @inbounds begin
        dst.ms1.s1 .= src.ms1.s1
        dst.ms1.s2 .= src.ms1.s2
        dst.ms1.s3 = src.ms1.s3

        dst.ms2.s4 .= src.ms2.s4
        dst.ms2.s5 = src.ms2.s5

        dst.ms3.s6 = src.ms3.s6
        dst.ms3.ms2.s4 .= src.ms3.ms2.s4
        dst.ms3.ms2.s5 = src.ms3.ms2.s5
    end
end

function sv_ms_nested_assign_std(dst, src)
    @uviews dst src @inbounds begin
        dst[1:50] .= view(src, 1:50)
        dst[51:55] .= view(src, 51:55)
        dst[56] = src[56]
        dst[57:59] .= view(src, 57:59)
        dst[60] = src[60]
        dst[61] = src[61]
        dst[62:64] .= view(src, 62:64)
        dst[65] = src[65]
    end
end


function sv_ms_assign()
    s1 = MatrixShape(Float64, 5,10)
    s2 = VectorShape(Float64, 15)
    s3 = ScalarShape(Float64)
    ms = MultiShape(s1 = s1, s2 = s2, s3=s3)

    src = rand!(allocate(ms))
    shaped_src = ms(rand!(allocate(ms)))
    dst = zeros(ms)
    shaped_dst = ms(zeros(ms))

    bench = @benchmarkable begin
        sv_ms_assign_bench($shaped_dst, $shaped_src)
    end teardown=(@assert $shaped_src == $shaped_dst)

    std = @benchmarkable begin
        sv_ms_assign_std($dst, $src)
    end teardown = @assert $dst == $src

    bench, std
end

function sv_ms_assign_bench(src, dst)
    @uviews dst src @inbounds begin
        dst.s1 .= src.s1
        dst.s2 .= src.s2
        dst.s3 = src.s3
    end
end

function sv_ms_assign_std(dst, src)
    @uviews dst src @inbounds begin
        dst[1:50] .= view(src, 1:50)
        dst[51:65] .= view(src, 51:65)
        dst[66] = src[66]
    end
end


function sv_vs_assign()
    s = VectorShape(Float64, 15)

    src = rand!(allocate(s))
    shaped_src = ShapedView(rand!(allocate(s)), s)
    dst = zeros(s)
    shaped_dst = ShapedView(zeros(s), s)

    bench = @benchmarkable begin
        @inbounds $shaped_dst .= $shaped_src
    end teardown=(@assert $shaped_src == $shaped_dst)
    std = @benchmarkable begin
        @inbounds $dst .= $src
    end
    bench, std
end

