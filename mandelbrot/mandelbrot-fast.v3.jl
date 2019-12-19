#=
The Computer Language Benchmarks Game
 https://salsa.debian.org/benchmarksgame-team/benchmarksgame/

 direct transliteration of the swift#3 program by Ralph Ganszky and Daniel Muellenborn:
 https://benchmarksgame-team.pages.debian.net/benchmarksgame/program/mandelbrot-swift-3.html

 modified for Julia 1.0 by Simon Danisch.
 tweaked for performance by https://github.com/maltezfaria and Adam Beckmeyer.
=#
using KissThreading

const zerov8 = ntuple(x-> 0f0, 8)
const masks = (0b01111111, 0b10111111, 0b11011111, 0b11101111, 0b11110111,
               0b11111011, 0b11111101, 0b11111110)

# Calculate mandelbrot set for one Vec8 into one byte
Base.@propagate_inbounds function mand8(cr, ci)
    Zr = Zi = Tr = Ti = t = zerov8
    i = 0

    for _=1:10
        for _=1:5
            Zi = 2f0 .* Zr .* Zi .+ ci
            Zr = Tr .- Ti .+ cr
            Tr = Zr .* Zr
            Ti = Zi .* Zi
        end
        t = Tr .+ Ti
        all(x-> x > 4f0, t) && (return 0x00)
    end

    byte = 0xff
    for i=1:8
        t[i] <= 4.0 || (byte &= masks[i])
    end
    return byte
end

function mandel_inner(rows, ci, y, N, xvals)
    @inbounds for x=1:8:N
        cr = ntuple(i-> xvals[x + i - 1], 8)
        rows[((y-1)*N÷8+(x-1)÷8) + 1] = mand8(cr, ci)
    end
end

function mandelbrot(io, n = 200)
    inv_ = 2.0 / n
    xvals = Vector{Float32}(undef, n)
    yvals = Vector{Float32}(undef, n)
    @inbounds for i in 0:(n-1)
        xvals[i + 1] = i * inv_ - 1.5
        yvals[i + 1] = i * inv_ - 1.0
    end

    rows = Vector{UInt8}(undef, n^2 ÷ 8)
    f(y) = @inbounds mandel_inner(rows, yvals[y], y, n, xvals)
    tmap!(f, Vector{Nothing}(undef, n), collect(1:n); batch_size=8)

    write(io, "P4\n$n $n\n")
    write(io, rows)
end

isinteractive() || mandelbrot(stdout, parse(Int, ARGS[1]))
