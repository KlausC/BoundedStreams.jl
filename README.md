# BoundedStreams.jl

[![Build Status](https://travis-ci.org/KlausC/BoundedStreams.jl.svg?branch=master)](https://travis-ci.org/KlausC/BoundedStreams.jl)
[![Codecov](https://codecov.io/gh/KlausC/BoundedStreams.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/KlausC/BoundedStreams.jl)

## Description

The `BoundedStreams` package describe a defined area in a source stream, which is defined
by an offset in the source stream and a length.

The `BoundedStream` objects may be understood as views to a section of their source streams.

All feasible access to stream (interface  `IO`) is supported.

## Usage

The public API of `BoundedStreams` includes the structure:

* `BoundedInputStream  <: IO` — defines an bounded input stream in its initial state
* `BoundedOutputStream <: IO` — defines an bounded output stream in its initial state

and corresponding construcors. All access is via the `IO` functions (`read`/`write`,
`skip`, `seek`, `mark`, `reset`, `isreadable`, `iswritable`, `eof`,
`close`, `position`, `bytesavailable`). They may be wrapped in other wrapping streams
as well. Some functions may be restricted due to backing the source stream.

### Installation
```julia
   ]add BoundedStreams
```

### Usage Example

```julia
    using BoundedStreams

    sourceio = open("filename.tar")
    io = BoundedInputStream(sourceio, 1000, offset=512)
    x = read(read(io, 10))
    skip(io, 100)
    y = read(io)
    ...
```
<!-- BEGIN: copied from inline doc strings -->

    BoundedInputStream(source::IO, nbytes::Integer; offset=0, close=nbytes)
    BoundedOutputStream(source::IO, nbytes::Integer; offset=0, close=nbytes)

Provide the `IO` interface for reading/writing the source stream `source`. Restrict the
number of bytes to to `nbytes`.

The optional integer argument `offset` shifts the starting point off the
current position of the source stream.

The optional argument `close` determines the position of the source stream after
this stream is closed. The special value `BoundedStreams.CLOSE` closes
the source stream in this case.

<!-- END: copied from inline doc strings -->
