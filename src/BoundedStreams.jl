module BoundedStreams

export BoundedInputStream, BoundedOutputStream

const CLOSE = typemin(Int64) # special value for optional `close` argument

# abstract base type for Input and Output
abstract type BoundedStream{T} <: IO end

"""
    BoundedInputStream(source::IO, nbytes::Integer; offset=0, close=nbytes)

Provide the `IO` interface for reading the source stream `source`. Restrict the number of
bytes to to `nbytes`. A `BoundedInputStream` can be considered as a view on the wrapped
stream, which starts at the position of that at the time of creation, and extends by the
given size. Trying to read beyond this area throws `EOFError`.

The optional integer argument `offset` shifts the starting point off the
current position of the source stream.

The optional argument `close` determines the position of the source stream after
this stream is closed. The special value `BoundedStreams.CLOSE` closes
the source stream in this case.
"""
struct BoundedInputStream{T} <: BoundedStream{T}
    source::T
    offset::Int64
    length::Int
    close::Int
    function BoundedInputStream(io::T, nb::Integer;
                                offset::Integer=0, close::Integer=nb) where T
        
        isreadable(io) || throw(ArgumentError("source stream is not readable"))
        new{T}(io, initposition!(io, offset), nb, close)
    end
end

"""
    BoundedOutputStream(source::IO, nbytes::Integer; offset=0, close=nbytes)

Provide the `IO` interface for writing the source stream `source`. Restrict the number of
bytes to to `nbytes`. A `BoundedOutputStream` can be considered as a view on the wrapped
stream, which starts at the position of that at the time of creation, and extends by the
given size. Trying to write beyond this area throws `EOFError`.

The optional integer argument `offset` shifts the starting point off the
current position of the source stream.

The optional argument `close` determines the position of the source stream after
this stream is closed. The special value `BoundedStreams.CLOSE` closes
the source stream in this case.
"""
struct BoundedOutputStream{T} <: BoundedStream{T}
    source::T
    offset::Int64
    length::Int
    close::Int
    function BoundedOutputStream(io::T, nb::Integer;
                                offset::Integer=0, close::Integer=nb) where T
        
        iswritable(io) || throw(ArgumentError("source stream is not writable"))
        new{T}(io, initposition!(io, offset), nb, close)
    end
end

# set position of stream, if required. prefer skip over seek if possible. return position.
function initposition!(io::IO, offset::Int64)
    if offset == 0
        position(io)
    elseif offset > 0
        skip(io, offset)
        position(io)
    elseif offset < 0
        pos = position(io) + offset
        seek(io, pos)
        pos
    end
end

function Base.bytesavailable(io::BoundedStream)
    a = io. length - position(io)
    0 <= a <= io.length ? a : 0
end
Base.position(io::BoundedStream) = position(io.source) - io.offset

function Base.eof(io::BoundedStream)
    bytesavailable(io) <= 0 || eof(io.source)
end

function Base.close(io::BoundedStream)
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

function Base.skip(io::BoundedStream, nb::Integer)
    stream = io.source
    nbmax = bytesavailable(io)
    0 <= nb <= nbmax || throw(ArgumentError("cannot skip outside BoundedStream"))
    skip(stream, nb)
    io
end

function Base.seek(io::BoundedStream, nb::Integer)
    0 <= nb <= io.length || throw(ArgumentError("cannot seek outside BoundedStream"))
    seek(io.source, io.offset + nb)
    io
end
Base.seekend(io::BoundedStream) = seek(io, io.length)

Base.isreadable(io::BoundedStream) = io isa BoundedInputStream
Base.iswritable(io::BoundedStream) = io isa BoundedOutputStream
Base.mark(io::BoundedStream) = mark(io.source)
Base.unmark(io::BoundedStream) = unmark(io.source)
Base.reset(io::BoundedStream) = reset(io.source)
Base.ismarked(io::BoundedStream) = ismarked(io.source)

function Base.readbytes!(io::BoundedInputStream, buf::Vector{UInt8}, nb::Integer)
    readbytes!(io.source, buf, min(nb, bytesavailable(io)))
end

function Base.read(io::BoundedInputStream, T::Type{UInt8})
    nb = bytesavailable(io)
    nb >= sizeof(T) || throw(EOFError())
    read(io.source, T)
end

function Base.unsafe_write(io::BoundedOutputStream, p::Ptr{UInt8}, n::UInt)
    nb = bytesavailable(io)
    nb >= n || throw(EOFError())
    Base.unsafe_write(io.source, p, n)
end

function Base.write(io::BoundedOutputStream, x::UInt8)
    nb = bytesavailable(io)
    nb >= 1 || throw(EOFError())
    write(io.source, x)
end

end # module
