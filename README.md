# BoundedStreams.jl

[![Build Status](https://travis-ci.org/JuliaLang/BoundedStreams.jl.svg?branch=master)](https://travis-ci.org/JuliaLang/BoundedStreams.jl)
[![Codecov](https://codecov.io/gh/JuliaLang/BoundedStreams.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/JuliaLang/BoundedStreams.jl)

## Design & Features

The `BoundedStreams` package describe a defined area in a source stream, which is defined
by an offset in the source stream and a length. It is not intended to modify this area.
All feasible acces to stream (interface  `IO`) is supported.
Currently only input streams are supported.

## API & Usage

The public API of `BoundedStreams` includes the structure:

* `BoundedInputStreami <: IO` — defines an bounded input stream in its initial state

and corresponding construcors. All access is via the `IO` functions. Some functions
may be restricted due to backing the source stream.

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

<!-- END: copied from inline doc strings -->
