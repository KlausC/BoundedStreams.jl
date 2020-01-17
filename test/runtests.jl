
using Test
using BoundedStreams

# setup test file
file = joinpath(mkpath(abspath(@__FILE__, "..", "data")), "test.dat")
open(file, "w") do io
    write(io, '0':'9', 'A':'Z', 'a':'z')
end

@testset "bounded input stream" begin
    open(file) do io
        bio = BoundedInputStream(io, 10)
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
        @test eof(io)
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

