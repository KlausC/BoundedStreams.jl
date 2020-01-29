
using Test
using BoundedStreams

# setup test file
file = joinpath(mkpath(abspath(@__FILE__, "..", "data")), "test.dat")

@testset "$(nameof(S)) general" for S in (BoundedInputStream, BoundedOutputStream)
    io = open(file, "w+")
    is = S(io, 100)
    @test isreadable(is) == (S <: BoundedInputStream)
    @test iswritable(is) == (S <: BoundedOutputStream)
    @test skip(is, 5) === is
    @test position(is) == 5
    @test !ismarked(is)
    @test mark(is) == 5
    @test ismarked(is)
    @test unmark(is)
    mark(is)
    @test seek(is, 1) === is
    @test position(is) == 1
    @test reset(is) == 5
    @test position(is) == 5
    @test bytesavailable(is) == 95
    close(is)
    @test bytesavailable(is) == 0
    @test position(io) == 100
    close(io)

    @test_throws ArgumentError BoundedInputStream(open(file, "w"), 10)
    @test_throws ArgumentError BoundedOutputStream(open(file, "r"), 10)
end

@testset "BoundedInputStream read" begin
    open(file, "w") do io
        write(io, '0':'9', 'A':'Z', 'a':'z')
    end
    open(file) do io
        bio = BoundedInputStream(io, 10, close=BoundedStreams.CLOSE)
        @test !eof(bio) 
        @test String(read(bio, 4)) == "0123"
        @test position(bio) == 4
        @test position(io) == 4
        @test bytesavailable(bio) == 6 
        @test String(read(bio, 5)) == "45678"
        @test position(bio) == 9
        @test bytesavailable(bio) == 1 
        @test !eof(bio)
        close(bio)
        @test eof(bio)
        @test eof(io)
    end

    open(file) do io
        bio = BoundedInputStream(io, 3, offset=10, close=26)
        @test String(read(bio)) == "ABC"
        @test position(bio) == 3
        @test position(io) == 13
        @test bytesavailable(bio) == 0
        @test String(read(bio)) == ""
        close(bio)
        @test position(bio) == 26
        @test position(io) == 36
        @test !eof(io)
        bio = BoundedInputStream(io, 5)
        @test String(read(bio)) == "abcde"
        close(bio)
        @test !eof(io)
    end

    open(file) do io
        off = 36
        bio = BoundedInputStream(io, 26, offset=off)
        seek(bio, 10)
        @test position(bio) == 10
        @test position(io) == off + 10
        @test String(read(bio, 2)) == "kl"
        seekstart(bio)
        @test position(bio) == 0
        @test position(io) == off
        seekend(bio)
        @test position(bio) == 26
        @test position(io) == off + 26
        seek(io, 10)
        @test position(bio) == 10 - off
        @test eof(bio)
        @test String(read(bio)) == ""
    end

    open(file) do io
        skip(io, 36)
        bio = BoundedInputStream(io, 40, offset=-26, close=50)
        @test position(io) == 10
        @test skip(bio, 5) === bio
        @test position(io) == 15
        @test seek(bio, 2) === bio
        @test_throws ArgumentError skip(bio, 100)
        @test_throws ArgumentError seek(bio, -200)
        seek(io, 62)
        @test close(bio) === nothing
        @test position(bio) == 50
    end

    open(file) do io
        bio = BoundedInputStream(io, 15)
        @test read(bio, Int) != nothing
        @test_throws EOFError read(bio, Int)
    end
end

@testset "BoundedOutputStream write" begin
    open(file, "w") do io
        bio = BoundedOutputStream(io, 20, offset=5, close=BoundedStreams.CLOSE)
        @test write(bio, UInt8(20)) == 1
        @test position(bio) == 1
        @test write(bio, Int64(123)) == 8
        @test position(bio) == 9
        @test bytesavailable(bio) == 11
        @test write(bio, "abcdefghij") == 10
        @test bytesavailable(bio) == 1
        @test_throws EOFError write(bio, "kl")
    end
    open(file, "r") do io
        @test skip(io, 5) === io
        @test read(io, UInt8) == 20
        @test read(io, Int64) == 123
        @test read(io, String) == "abcdefghij"
    end
end
