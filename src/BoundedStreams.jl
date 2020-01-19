module BoundedStreams

export BoundedInputStream

"""
    BoundedInputStream(source::IO, nbytes::Integer) <: IO

Provide the `IO` interface for reading the source stream `source`. Restrict the number of
bytes to to `nbytes`.
"""
struct BoundedInputStream{T} <: IO
    source::T
    offset::Int64
    length::Int
    close::Int
    function BoundedInputStream(io::T, nb::Integer;
                                offset::Integer=0, close::Integer=nb) where T
        if offset > 0
            skip(io, offset)
        elseif offset < 0
            seek(io, position(io) + offset)
        end
        new{T}(io, position(io), nb, close)
    end
end

const CLOSE = typemin(Int)

function Base.bytesavailable(io::BoundedInputStream)
    a = io. length - position(io)
    0 <= a <= io.length ? a : 0
end
Base.position(io::BoundedInputStream) = position(io.source) - io.offset

function Base.readbytes!(io::BoundedInputStream, buf::Vector{UInt8}, nb::Integer)
    readbytes!(io.source, buf, min(nb, bytesavailable(io)))
end

function Base.eof(io::BoundedInputStream)
    bytesavailable(io) <= 0 || eof(io.source)
end

function Base.close(io::BoundedInputStream)
    source = io.source
    if io.close == CLOSE
        close(source)
    else
        p = position(source)
        q = io.offset + io.close
        if p < q 
            skip(source, q - p)
        elseif p > q
            seek(source, q)
        end
    end
    nothing
end

function Base.skip(io::BoundedInputStream, nb::Integer)
    stream = io.source
    nbmax = bytesavailable(io)
    0 <= nb <= nbmax || throw(ArgumentError("cannot skip outside BoundedStream"))
    skip(stream, nb)
    io
end

function Base.seek(io::BoundedInputStream, nb::Integer)
    0 <= nb <= io.length || throw(ArgumentError("cannot seek outside BoundedStream"))
    seek(io.source, io.offset + nb)
    io
end
Base.seekend(io::BoundedInputStream) = seek(io, io.length)

function Base.read(io::BoundedInputStream, T::Type{UInt8})
    nb = bytesavailable(io)
    nb >= sizeof(T) || throw(EOFError())
    read(io.source, T)
end

end # module
