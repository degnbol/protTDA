#!/usr/bin/env julia
using Printf: format

"""
Macro @sprintf only allows first arg to be a string literal 
so when we want the formatting string to be a variable we have to use 
Printf.format which needs the formatting string to explicitly 
be of type Printf.Format so we make it implicit for convenience.
"""
function Printf.format(fmt::AbstractString, args...)
    Printf.format(Printf.Format(fmt), args...)
end

